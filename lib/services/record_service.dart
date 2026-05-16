import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RecordService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<bool> addRecord({
    required String title,
    required String description,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;
      
      await _firestore.collection('records').add({
        'userId': userId,
        'title': title,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Add record error: $e');
      return false;
    }
  }
}