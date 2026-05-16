import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  // Default koordinat Surabaya (Tugu Pahlawan)
  static const double defaultLatitude = -7.2458;
  static const double defaultLongitude = 112.7378;
  static const String defaultCity = "Surabaya";

  /// Cek apakah GPS menyala
  Future<bool> isGPSEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Buka pengaturan GPS
  Future<void> openGPSSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Dapatkan lokasi GPS (return null jika tidak ada)
  Future<Position?> getCurrentLocation() async {
    // Cek GPS enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Cek permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Dapatkan lokasi valid (GPS atau fallback Surabaya)
  Future<LocationData> getValidLocation() async {
    final Position? gpsLocation = await getCurrentLocation();
    
    if (gpsLocation != null) {
      return LocationData(
        latitude: gpsLocation.latitude,
        longitude: gpsLocation.longitude,
        city: defaultCity,
        isGPSActive: true,
      );
    } else {
      return LocationData(
        latitude: defaultLatitude,
        longitude: defaultLongitude,
        city: defaultCity,
        isGPSActive: false,
      );
    }
  }
  // TAMBAHKAN METHOD INI
/// Simpan lokasi terakhir user ke Firestore (untuk history aktivitas)
Future<void> saveLastLocationToFirestore({
  required double latitude,
  required double longitude,
  required String placeName,
}) async {
  try {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('activities')
        .add({
      'type': 'location',
      'title': 'Berada di $placeName',
      'latitude': latitude,
      'longitude': longitude,
      'placeName': placeName,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    // Juga simpan sebagai dokumen terpisah untuk lokasi terakhir
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set({
          'lastLocation': GeoPoint(latitude, longitude),
          'lastPlaceName': placeName,
          'lastLocationUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
    print('✅ Lokasi tersimpan ke Firestore');
  } catch (e) {
    print('❌ Gagal simpan lokasi: $e');
  }
}
}

class LocationData {
  final double latitude;
  final double longitude;
  final String city;
  final bool isGPSActive;
  
  LocationData({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.isGPSActive,
  });
}