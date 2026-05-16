// lib/services/google_maps_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class HealthFacility {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String type;
  final String category;
  final String phone;
  final String openHours;
  double distanceM;

  HealthFacility({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.type,
    required this.category,
    this.phone = '-',
    this.openHours = '-',
    this.distanceM = 0,
  });

  String get distanceText {
    if (distanceM < 1000) return '${distanceM.round()} m';
    return '${(distanceM / 1000).toStringAsFixed(1)} km';
  }
}

class HealthFacilityService {

  static Future<Position> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return _defaultLocation();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return _defaultLocation();
    }
    if (permission == LocationPermission.deniedForever) return _defaultLocation();

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return _defaultLocation();
    }
  }

  static Position _defaultLocation() {
    return Position(
      latitude: -7.2575,
      longitude: 112.7521,
      timestamp: DateTime.now(),
      accuracy: 0, altitude: 0, altitudeAccuracy: 0,
      heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
    );
  }

  static Future<List<HealthFacility>> searchNearby({
    required double lat,
    required double lng,
    int radiusM = 5000,
    String type = 'ALL',
  }) async {
    final List<String> amenities = _getAmenities(type);
    final List<HealthFacility> results = [];

    for (final amenity in amenities) {
      try {
        final query = '''
          [out:json][timeout:20];
          (
            node["amenity"="$amenity"](around:$radiusM,$lat,$lng);
            way["amenity"="$amenity"](around:$radiusM,$lat,$lng);
          );
          out center 30;
        ''';

        final response = await http.post(
          Uri.parse('https://overpass-api.de/api/interpreter'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: 'data=${Uri.encodeComponent(query)}',
        ).timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final elements = data['elements'] as List? ?? [];

          for (final el in elements) {
            final tags = el['tags'] as Map? ?? {};
            final name = tags['name'] as String?;
            if (name == null || name.isEmpty) continue;

            final double elLat = (el['lat'] ?? el['center']?['lat'] ?? lat).toDouble();
            final double elLng = (el['lon'] ?? el['center']?['lon'] ?? lng).toDouble();
            final dist = Geolocator.distanceBetween(lat, lng, elLat, elLng);
            final address = _buildAddress(tags);

            results.add(HealthFacility(
              id: el['id'].toString(),
              name: name,
              address: address,
              lat: elLat,
              lng: elLng,
              type: amenity,
              category: _categoryLabel(amenity),
              phone: tags['phone'] ?? tags['contact:phone'] ?? '-',
              openHours: tags['opening_hours'] ?? '-',
              distanceM: dist,
            ));
          }
        }
      } catch (_) {
        continue;
      }
    }

    if (results.isEmpty) {
      print('⚠️ Overpass API returned no results, using fallback data');
      return _getFallbackFacilities(lat, lng, type);
    }

    final seen = <String>{};
    final unique = results.where((f) => seen.add(f.id)).toList();
    unique.sort((a, b) => a.distanceM.compareTo(b.distanceM));
    return unique;
  }

  static List<String> _getAmenities(String type) {
    switch (type) {
      case 'hospital': return ['hospital'];
      case 'pharmacy': return ['pharmacy'];
      case 'health':   return ['clinic', 'health_post'];
      case 'clinic':   return ['doctors', 'clinic'];
      default:         return ['hospital', 'pharmacy', 'clinic', 'doctors'];
    }
  }

  static String _categoryLabel(String amenity) {
    switch (amenity) {
      case 'hospital': return 'Rumah Sakit';
      case 'pharmacy': return 'Apotek';
      case 'clinic': case 'health_post': return 'Puskesmas / Klinik';
      case 'doctors': return 'Faskes';
      default: return 'Fasilitas Kesehatan';
    }
  }

  static String _buildAddress(Map tags) {
    final parts = <String>[];
    if (tags['addr:street'] != null) {
      String street = tags['addr:street'];
      if (tags['addr:housenumber'] != null) {
        street += ' No.${tags['addr:housenumber']}';
      }
      parts.add(street);
    }
    if (tags['addr:suburb'] != null) parts.add(tags['addr:suburb']);
    if (tags['addr:city'] != null) parts.add(tags['addr:city']);
    if (parts.isEmpty) return tags['description'] ?? 'Alamat tidak tersedia';
    return parts.join(', ');
  }

  static List<HealthFacility> _getFallbackFacilities(double lat, double lng, String type) {
    List<HealthFacility> fallback = [];
    
    final fallbackData = [
      {'name': 'RSUD Dr. Soetomo', 'lat': -7.2644, 'lng': 112.7648, 'address': 'Jl. Prof. Dr. Moestopo No.6-8', 'type': 'hospital'},
      {'name': 'RS Islam Surabaya', 'lat': -7.3042, 'lng': 112.7341, 'address': 'Jl. Ahmad Yani No.2-4', 'type': 'hospital'},
      {'name': 'RS Darmo', 'lat': -7.2872, 'lng': 112.7356, 'address': 'Jl. Raya Darmo No.90', 'type': 'hospital'},
      {'name': 'RS William Booth', 'lat': -7.2776, 'lng': 112.7245, 'address': 'Jl. Mayjen Sungkono No.120', 'type': 'hospital'},
      {'name': 'RSAL Dr. Ramelan', 'lat': -7.2452, 'lng': 112.7526, 'address': 'Jl. Gadung No.1', 'type': 'hospital'},
      {'name': 'Apotek Kimia Farma', 'lat': -7.2575, 'lng': 112.7521, 'address': 'Jl. Basuki Rahmat No.45', 'type': 'pharmacy'},
      {'name': 'Apotek Century', 'lat': -7.2872, 'lng': 112.7356, 'address': 'Jl. Raya Darmo No.89', 'type': 'pharmacy'},
      {'name': 'Puskesmas Kalirungkut', 'lat': -7.3129, 'lng': 112.7635, 'address': 'Jl. Kalirungkut No.2', 'type': 'health'},
      {'name': 'Puskesmas Wonokromo', 'lat': -7.3042, 'lng': 112.7341, 'address': 'Jl. Wonokromo No.10', 'type': 'health'},
    ];
    
    final filteredData = fallbackData.where((data) {
      final dataType = data['type'] as String;
      if (type == 'ALL') return true;
      if (type == 'hospital') return dataType == 'hospital';
      if (type == 'pharmacy') return dataType == 'pharmacy';
      if (type == 'health') return dataType == 'health';
      return false;
    }).toList();
    
    for (var data in filteredData) {
      final name = data['name'] as String;
      final address = data['address'] as String;
      final lat2 = data['lat'] as double;
      final lng2 = data['lng'] as double;
      final dataType = data['type'] as String;
      
      final distance = Geolocator.distanceBetween(lat, lng, lat2, lng2);
      
      fallback.add(HealthFacility(
        id: name.replaceAll(' ', '_'),
        name: name,
        address: address,
        lat: lat2,
        lng: lng2,
        type: dataType,
        category: _categoryLabel(dataType),
        phone: '-',
        openHours: '-',
        distanceM: distance,
      ));
    }
    
    fallback.sort((a, b) => a.distanceM.compareTo(b.distanceM));
    print('✅ Using ${fallback.length} fallback facilities');
    return fallback;
  }
}