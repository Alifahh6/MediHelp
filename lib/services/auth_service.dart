import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {  // ← UBAH INI
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Stream<User?> get user => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  
  Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final User? user = result.user;
      
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phone': phone,
          'photoUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        await user.updateDisplayName(name);
        await user.reload();
      }
      
      notifyListeners();  // ← TAMBAHKAN INI
      return user;
    } catch (e) {
      print('Register error: $e');
      return null;
    }
  }
  
  Future<User?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();  // ← TAMBAHKAN INI
      return result.user;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }
  
  Future<void> logout() async {
    await _auth.signOut();
    notifyListeners();  // ← TAMBAHKAN INI
  }
  
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser == null) return null;
    
    final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
    return doc.data();
  }
  
  Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    if (currentUser == null) return;
    
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    data['updatedAt'] = FieldValue.serverTimestamp();
    
    await _firestore.collection('users').doc(currentUser!.uid).update(data);
    
    if (name != null) {
      await currentUser!.updateDisplayName(name);
      await currentUser!.reload();
    }
    notifyListeners();  // ← TAMBAHKAN INI
  }
}