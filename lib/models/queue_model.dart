import 'package:cloud_firestore/cloud_firestore.dart';

class QueueModel {
  final String id;
  final String userId;
  final String userName;
  final String facilityId;
  final String facilityName;
  final int queueNumber;
  final String complaint;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String date;

  QueueModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.facilityId,
    required this.facilityName,
    required this.queueNumber,
    required this.complaint,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.date,
  });

  factory QueueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QueueModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      facilityId: data['facilityId'] ?? '',
      facilityName: data['facilityName'] ?? '',
      queueNumber: data['queueNumber'] ?? 0,
      complaint: data['complaint'] ?? '',
      status: data['status'] ?? 'waiting',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      date: data['date'] ?? '',
    );
  }
}