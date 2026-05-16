// lib/providers/activity_provider.dart
// ActivityProvider hanya dipakai untuk addActivity() dari screen lain
// (reminder_screen, queue_screen) agar tercatat ke Firestore.
// Tampilan list aktivitas dibaca langsung via StreamBuilder di activity_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityItem {
  final String title;
  final String action;
  final DateTime dateTime;
  final IconData icon;
  final Color color;
  final String type;

  ActivityItem({
    required this.title,
    required this.action,
    required this.dateTime,
    required this.icon,
    required this.color,
    required this.type,
  });
}

class ActivityProvider extends ChangeNotifier {
  // Tambah aktivitas langsung ke Firestore
  Future<void> addActivity(ActivityItem item) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activities')
          .add({
        'type': item.type,
        'title': item.title,
        'description': item.action,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Activity saved: ${item.title}');
    } catch (e) {
      debugPrint('❌ Failed to save activity: $e');
    }
  }
}