import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Simpan riwayat pencarian fasilitas
  Future<void> saveSearchHistory({
    required String facilityId,
    required String facilityName,
    required String facilityType,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    await _firestore.collection('search_history').add({
      'userId': userId,
      'facilityId': facilityId,
      'facilityName': facilityName,
      'facilityType': facilityType,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  
  // Ambil riwayat pencarian user
  Stream<QuerySnapshot> getSearchHistory() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.empty();
    
    return _firestore
        .collection('search_history')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
  }
  
  // Simpan riwayat ambil antrian
  Future<void> saveQueueHistory({
    required String facilityId,
    required String facilityName,
    required int queueNumber,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    await _firestore.collection('queue_history').add({
      'userId': userId,
      'facilityId': facilityId,
      'facilityName': facilityName,
      'queueNumber': queueNumber,
      'status': 'completed',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  
  // Ambil semua riwayat (search + queue)
  Future<List<Map<String, dynamic>>> getAllHistory() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];
    
    // Ambil search history
    final searchSnapshot = await _firestore
        .collection('search_history')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(30)
        .get();
    
    // Ambil queue history
    final queueSnapshot = await _firestore
        .collection('queue_history')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(30)
        .get();
    
    final List<Map<String, dynamic>> history = [];
    
    for (var doc in searchSnapshot.docs) {
      history.add({
        'type': 'search',
        'title': doc['facilityName'],
        'subtitle': 'Mencari ${doc['facilityType']}',
        'timestamp': doc['timestamp'],
        'data': doc.data(),
      });
    }
    
    for (var doc in queueSnapshot.docs) {
      history.add({
        'type': 'queue',
        'title': doc['facilityName'],
        'subtitle': 'Antrian nomor ${doc['queueNumber']}',
        'timestamp': doc['timestamp'],
        'data': doc.data(),
      });
    }
    
    // Urutkan berdasarkan timestamp
    history.sort((a, b) {
      final aTime = a['timestamp'] as Timestamp?;
      final bTime = b['timestamp'] as Timestamp?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.toDate().compareTo(aTime.toDate());
    });
    
    return history;
  }
}