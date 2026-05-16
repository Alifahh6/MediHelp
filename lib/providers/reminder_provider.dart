// lib/providers/reminder_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medi_help/providers/app_settings_provider.dart';

class ReminderProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _reminders = [];
  AppSettingsProvider? _settingsProvider;

  void setSettingsProvider(AppSettingsProvider provider) {
    _settingsProvider = provider;
  }

  List<Map<String, dynamic>> get reminders => List.unmodifiable(_reminders);

  // Alias
  Future<void> loadReminders() => loadRemindersFromFirestore();

  // ─── LOAD dari Firestore ──────────────────────────────────
  Future<void> loadRemindersFromFirestore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _reminders = [];
      notifyListeners();
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('reminders')
          .orderBy('addedAt', descending: true)
          .get();

      _reminders = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'times': (data['times'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              <String>[],
          'doses': (data['doses'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              <String>[],
          'rules': data['rules'] ?? '',
          'days': data['days'] ?? 0,
          'purpose': data['purpose'] ?? '',
          'isActive': data['isActive'] ?? true,
          'addedAt':
              (data['addedAt'] as Timestamp?)?.toDate().toIso8601String() ??
                  DateTime.now().toIso8601String(),
        };
      }).toList();

      notifyListeners();
      debugPrint('✅ Loaded ${_reminders.length} reminders from Firestore');
    } catch (e) {
      debugPrint('❌ Error loading reminders: $e');
    }
  }

  // ─── TAMBAH REMINDER ─────────────────────────────────────
  Future<void> addReminder(Map<String, dynamic> reminder) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final times =
          (reminder['times'] as List).map((e) => e.toString()).toList();
      final doses =
          (reminder['doses'] as List).map((e) => e.toString()).toList();

      // 1. Simpan ke reminders
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('reminders')
          .add({
        'name': reminder['name'],
        'times': times,
        'doses': doses,
        'rules': reminder['rules'],
        'days': reminder['days'],
        'purpose': reminder['purpose'],
        'isActive': reminder['isActive'] ?? true,
        'addedAt': FieldValue.serverTimestamp(),
      });

      // 2. Simpan ke medication_history ← INI YANG BIKIN HISTORY NYAMBUNG
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('medication_history')
          .add({
        'name': reminder['name'],
        'purpose': reminder['purpose'] == '-' ? '' : reminder['purpose'],
        'date': FieldValue.serverTimestamp(),
        'source': 'reminder',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Rekam ke activities
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activities')
          .add({
        'type': 'reminder',
        'title': 'Buat reminder: ${reminder['name']}',
        'description': 'Waktu: ${times.join(", ")}',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 4. Tambah ke local list
      final reminderWithId = {
        ...reminder,
        'id': docRef.id,
        'times': times,
        'doses': doses,
      };
      _reminders.insert(0, reminderWithId);
      notifyListeners();

      // 5. Kirim notifikasi
      if (_settingsProvider != null &&
          _settingsProvider!.notificationsEnabled) {
        final name = reminder['name'] ?? 'Obat';
        final timesStr = times.join(', ');
        await _settingsProvider!
            .showMedicationReminder('$name\nWaktu: $timesStr');
      }

      debugPrint('✅ Reminder + medication_history saved to Firestore');
    } catch (e) {
      debugPrint('❌ Failed to save reminder: $e');
    }
  }

  // ─── UPDATE REMINDER ─────────────────────────────────────
  Future<void> updateReminder(int index, Map<String, dynamic> data) async {
    if (index < 0 || index >= _reminders.length) return;

    final reminder = _reminders[index];
    final docId = reminder['id'];
    final userId = FirebaseAuth.instance.currentUser?.uid;

    final times =
        (data['times'] as List).map((e) => e.toString()).toList();
    final doses =
        (data['doses'] as List).map((e) => e.toString()).toList();

    final updated = {
      ...reminder,
      ...data,
      'times': times,
      'doses': doses,
    };

    _reminders[index] = updated;
    notifyListeners();

    if (userId != null && docId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('reminders')
            .doc(docId)
            .update({
          'name': data['name'],
          'times': times,
          'doses': doses,
          'rules': data['rules'],
          'days': data['days'],
          'purpose': data['purpose'],
        });
        debugPrint('✅ Reminder updated in Firestore');
      } catch (e) {
        debugPrint('❌ Failed to update reminder: $e');
      }
    }
  }

  // ─── TOGGLE REMINDER ─────────────────────────────────────
  Future<void> toggleReminder(int index, bool value) async {
    if (index >= 0 && index < _reminders.length) {
      final reminder = _reminders[index];
      reminder['isActive'] = value;
      notifyListeners();

      final userId = FirebaseAuth.instance.currentUser?.uid;
      final docId = reminder['id'];
      if (userId != null && docId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('reminders')
            .doc(docId)
            .update({'isActive': value});
      }

      if (value &&
          _settingsProvider != null &&
          _settingsProvider!.notificationsEnabled) {
        final name = reminder['name'] ?? 'Obat';
        await _settingsProvider!
            .showMedicationReminder('$name diaktifkan kembali');
      }
    }
  }

  // ─── HAPUS REMINDER ──────────────────────────────────────
  Future<void> removeReminder(int index) async {
    if (index >= 0 && index < _reminders.length) {
      final reminder = _reminders[index];
      final docId = reminder['id'];
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null && docId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('reminders')
            .doc(docId)
            .delete();
      }

      _reminders.removeAt(index);
      notifyListeners();
      debugPrint('✅ Reminder deleted from Firestore');
    }
  }
}