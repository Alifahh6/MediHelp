// lib/models/facility_model.dart
// TAMBAHKAN IMPORT INI DI PALING ATAS
import 'package:cloud_firestore/cloud_firestore.dart';

class FacilityModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String phone;
  final String type;
  final String openHours;
  final bool isOpen24h;
  final int queueEstimate;
  final String imageUrl;

  FacilityModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.type,
    required this.openHours,
    required this.isOpen24h,
    this.queueEstimate = 0,
    this.imageUrl = '',
  });

  // From Firestore - PERBAIKI INI
  factory FacilityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FacilityModel(
      id: doc.id,
      name: data['name'] ?? 'Tidak diketahui',
      address: data['address'] ?? '-',
      city: data['city'] ?? 'Surabaya',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      phone: data['phone'] ?? '-',
      type: data['type'] ?? 'clinic',
      openHours: data['openHours'] ?? '24 Jam',
      isOpen24h: data['isOpen24h'] ?? false,
      queueEstimate: data['queueEstimate'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  // To Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'type': type,
      'openHours': openHours,
      'isOpen24h': isOpen24h,
      'queueEstimate': queueEstimate,
      'imageUrl': imageUrl,
    };
  }
}