// lib/services/session_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SessionService extends ChangeNotifier {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  bool _isLoading = false;
  bool _isInitialized = false;

  bool _isLoggedIn = false;
  String? _userName;
  String? _userEmail;
  String? _userUid;

  int _totalUsers = 0;
  DateTime? _appStartDate;

  bool get isLoggedIn => _isLoggedIn;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userUid => _userUid;
  bool get isInitialized => _isInitialized;
  bool get mounted => true;
  String? get userPhone => null;

  int get totalUsers => _totalUsers;
  int get appAgeDays {
    if (_appStartDate == null) return 0;
    return DateTime.now().difference(_appStartDate!).inDays;
  }

  final RegExp _emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');

  // ─── GOOGLE SIGN IN (dipanggil langsung dari screen) ──────
  // Mengembalikan true jika berhasil
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Trigger Google Sign In popup
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return false; // user cancel

      // Dapatkan auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Buat Firebase credential dari Google token
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in ke Firebase Auth dengan Google credential
      final UserCredential result =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = result.user;

      if (user == null) return false;

      _userUid = user.uid;
      _userName = user.displayName ?? googleUser.displayName ?? 'User';
      _userEmail = user.email ?? googleUser.email;
      _isLoggedIn = true;
      _isInitialized = true;

      // Simpan / update ke Firestore
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        // User baru — buat dokumen baru
        await docRef.set({
          'uid': user.uid,
          'name': _userName,
          'email': _userEmail,
          'phone': '',
          'photoUrl': user.photoURL ?? '',
          'provider': 'google',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
        await _incrementTotalUsers();
        debugPrint('✅ Google user baru disimpan ke Firestore');
      } else {
        // User lama — update lastLogin saja
        await docRef.update({
          'lastLogin': FieldValue.serverTimestamp(),
          'photoUrl': user.photoURL ?? '',
        });
        // Ambil nama dari Firestore kalau ada
        _userName = doc.data()?['name'] ?? _userName;
        debugPrint('✅ Google user lama login, lastLogin diupdate');
      }

      // Simpan ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', _userName!);
      await prefs.setString('userEmail', _userEmail!);

      await _loadAndFixStats();
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Google Firebase Auth error: ${e.code} — ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Google Sign In error: $e');
      return false;
    }
  }

  // ─── LOAD SESSION ─────────────────────────────────────────
  Future<void> loadSession() async {
    if (_isInitialized || _isLoading) return;
    _isLoading = true;
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _isLoggedIn = true;
        _userUid = firebaseUser.uid;
        _userName =
            firebaseUser.displayName ?? firebaseUser.email?.split('@')[0];
        _userEmail = firebaseUser.email;
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .get();
          if (doc.exists) {
            _userName = doc.data()?['name'] ?? _userName;
            _userEmail = doc.data()?['email'] ?? _userEmail;
          }
        } catch (_) {}
      } else {
        final prefs = await SharedPreferences.getInstance();
        _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        _userName = prefs.getString('userName');
        _userEmail = prefs.getString('userEmail');
      }
      await _loadAndFixStats();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading session: $e');
      _isInitialized = false;
    } finally {
      _isLoading = false;
    }
  }

  // ─── STATS ────────────────────────────────────────────────
  Future<void> _loadAndFixStats() async {
    try {
      final ref =
          FirebaseFirestore.instance.collection('app_stats').doc('global');
      final snap = await ref.get();

      if (!snap.exists) {
        final usersSnap =
            await FirebaseFirestore.instance.collection('users').get();
        final count = usersSnap.docs.length;
        await ref.set({
          'totalUsers': count,
          'appStartDate': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        _totalUsers = count;
        _appStartDate = DateTime.now();
      } else {
        final data = snap.data()!;
        _totalUsers = (data['totalUsers'] as num?)?.toInt() ?? 0;
        final ts = data['appStartDate'] as Timestamp?;
        _appStartDate = ts?.toDate();

        if (_totalUsers == 0) {
          final usersSnap =
              await FirebaseFirestore.instance.collection('users').get();
          final real = usersSnap.docs.length;
          if (real > 0) {
            await ref.update({'totalUsers': real});
            _totalUsers = real;
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading stats: $e');
    }
  }

  Future<void> _incrementTotalUsers() async {
    try {
      final ref =
          FirebaseFirestore.instance.collection('app_stats').doc('global');
      final snap = await ref.get();
      if (snap.exists) {
        await ref.update({'totalUsers': FieldValue.increment(1)});
        _totalUsers++;
      } else {
        final usersSnap =
            await FirebaseFirestore.instance.collection('users').get();
        final count = usersSnap.docs.length;
        await ref.set({
          'totalUsers': count,
          'appStartDate': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        _totalUsers = count;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error incrementing users: $e');
    }
  }

  // ─── LOGIN ────────────────────────────────────────────────
  Future<bool> login(String email, String password, {String? name}) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();

    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) return false;
    if (!_emailRegex.hasMatch(trimmedEmail)) return false;
    if (trimmedPassword.length < 6) return false;
    if (_isLoading) return false;

    _isLoading = true;
    try {
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );
      final user = result.user;
      if (user == null) return false;

      _userUid = user.uid;
      _userEmail = trimmedEmail;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        _userName = doc.exists
            ? (doc.data()?['name'] ??
                user.displayName ??
                trimmedEmail.split('@')[0])
            : (user.displayName ?? trimmedEmail.split('@')[0]);
      } catch (_) {
        _userName = user.displayName ?? trimmedEmail.split('@')[0];
      }

      _isLoggedIn = true;
      _isInitialized = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', _userName!);
      await prefs.setString('userEmail', _userEmail!);

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'lastLogin': FieldValue.serverTimestamp()});
      } catch (_) {}

      await _loadAndFixStats();
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase login error: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    } finally {
      _isLoading = false;
    }
  }

  // ─── REGISTER ─────────────────────────────────────────────
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? confirmPassword,
    String? phone,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();
    final trimmedName = name.trim();

    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty || trimmedName.isEmpty)
      return false;
    if (!_emailRegex.hasMatch(trimmedEmail)) return false;
    if (trimmedPassword.length < 6) return false;
    if (confirmPassword != null &&
        trimmedPassword != confirmPassword.trim()) return false;
    if (_isLoading) return false;

    _isLoading = true;
    try {
      final result =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );
      final user = result.user;
      if (user == null) return false;

      await user.updateDisplayName(trimmedName);
      await user.reload();

      _userUid = user.uid;
      _userName = trimmedName;
      _userEmail = trimmedEmail;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': trimmedName,
        'email': trimmedEmail,
        'phone': phone ?? '',
        'photoUrl': '',
        'provider': 'email',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      await _incrementTotalUsers();

      _isLoggedIn = true;
      _isInitialized = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', _userName!);
      await prefs.setString('userEmail', _userEmail!);

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase register error: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    } finally {
      _isLoading = false;
    }
  }

  // ─── LOGOUT ───────────────────────────────────────────────
  Future<void> logout() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      // Sign out dari Google juga
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();

      _isLoggedIn = false;
      _userName = null;
      _userEmail = null;
      _userUid = null;
      _isInitialized = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userName');
      await prefs.remove('userEmail');
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
      _isLoggedIn = false;
      _userName = null;
      _userEmail = null;
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  // ─── UPDATE PROFILE ───────────────────────────────────────
  Future<bool> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    if (!_isLoggedIn) return false;
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    if (trimmedName.isEmpty || trimmedEmail.isEmpty) return false;
    if (!_emailRegex.hasMatch(trimmedEmail)) return false;
    if (_isLoading) return false;
    _isLoading = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _userUid != null) {
        await user.updateDisplayName(trimmedName);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userUid!)
            .update({
          'name': trimmedName,
          'email': trimmedEmail,
          if (phone != null) 'phone': phone.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      _userName = trimmedName;
      _userEmail = trimmedEmail;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _userName!);
      await prefs.setString('userEmail', _userEmail!);
      if (phone != null && phone.trim().isNotEmpty) {
        await prefs.setString('userPhone', phone.trim());
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return false;
    } finally {
      _isLoading = false;
    }
  }

  // ─── CHECK LOGIN ──────────────────────────────────────────
  Future<bool> checkLogin(BuildContext context, VoidCallback onSuccess) async {
    if (!_isInitialized && !_isLoading) await loadSession();
    if (_isLoading) await Future.delayed(const Duration(milliseconds: 100));
    if (!_isLoggedIn) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Login Diperlukan'),
            content:
                const Text('Silakan login untuk menggunakan fitur ini'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  if (context.mounted)
                    Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F5E7A)),
                child: const Text('Login'),
              ),
            ],
          ),
        );
      }
      return false;
    }
    if (context.mounted) onSuccess();
    return true;
  }

  Future<void> clearAllData() async {
    try {
      final googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _isLoggedIn = false;
      _userName = null;
      _userEmail = null;
      _userUid = null;
      _isInitialized = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }
}