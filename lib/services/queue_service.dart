import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class QueueService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<bool> takeQueue({
    required String facilityId,
    required String facilityName,
    required String complaint,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;
      
      await _firestore.collection('queues').add({
        'userId': userId,
        'facilityId': facilityId,
        'facilityName': facilityName,
        'complaint': complaint,
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Take queue error: $e');
      return false;
    }
  }
}