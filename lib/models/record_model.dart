import 'package:cloud_firestore/cloud_firestore.dart';

class RecordModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final DateTime date;
  final DateTime createdAt;

  RecordModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.date,
    required this.createdAt,
  });

  factory RecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecordModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'note',
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}