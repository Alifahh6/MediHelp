// lib/providers/location_provider.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum LocationStatus { idle, loading, success, failed, denied, disabled }

class NearbyFacility {
  final String name;
  final String type;
  final String category;
  final String address;
  final String distance;
  final double distanceRaw;
  final String phone;
  final String queue;
  final String waitTime;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final double lat;
  final double lng;

  const NearbyFacility({
    required this.name,
    required this.type,
    required this.category,
    required this.address,
    required this.distance,
    required this.distanceRaw,
    required this.phone,
    required this.queue,
    required this.waitTime,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.lat,
    required this.lng,
  });
}

class LocationProvider extends ChangeNotifier {
  static final LocationProvider _instance = LocationProvider._internal();
  factory LocationProvider() => _instance;
  LocationProvider._internal();

  LocationStatus       _status           = LocationStatus.idle;
  double?              _lat;
  double?              _lng;
  bool                 _isDefault        = false;
  bool                 _isOverpassFail   = false;
  String               _locationLabel    = '📍 Mendeteksi...';
  List<NearbyFacility> _facilities       = [];
  bool                 _facilitiesLoaded = false;

  LocationStatus       get status           => _status;
  double?              get lat              => _lat;
  double?              get lng              => _lng;
  bool                 get isDefault        => _isDefault;
  bool                 get isOverpassFail   => _isOverpassFail;
  bool                 get hasLocation      => _lat != null && _lng != null;
  String               get locationLabel    => _locationLabel;
  List<NearbyFacility> get facilities       => _facilities;
  bool                 get isLoading        => _status == LocationStatus.loading;
  bool                 get facilitiesLoaded => _facilitiesLoaded;

  Future<void> init({bool forceRefresh = false}) async {
    if (_status == LocationStatus.success && !forceRefresh) return;
    await _fetchLocation();
  }

  Future<void> refresh() => _fetchLocation();

  // ── Step 1: GPS ────────────────────────────────────────────────────────────
  Future<void> _fetchLocation() async {
    _status           = LocationStatus.loading;
    _facilitiesLoaded = false;
    _isOverpassFail   = false;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _loadFacilities(-7.2575, 112.7521, isDefault: true);
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _status = LocationStatus.denied;
        await _loadFacilities(-7.2575, 112.7521, isDefault: true);
        return;
      }

      Position? pos;

      // Last known (instan)
      try { pos = await Geolocator.getLastKnownPosition(); } catch (_) {}

      // Network location
      if (pos == null) {
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.lowest,
              timeLimit: Duration(seconds: 15),
            ),
          ).timeout(const Duration(seconds: 17));
        } catch (_) { pos = null; }
      }

      // GPS
      if (pos == null) {
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 30),
            ),
          ).timeout(const Duration(seconds: 35));
        } catch (_) { pos = null; }
      }

      if (pos == null) {
        await _loadFacilities(-7.2575, 112.7521, isDefault: true);
        return;
      }

      _lat           = pos.latitude;
      _lng           = pos.longitude;
      _isDefault     = false;
      _locationLabel = '📍 ${pos.latitude.toStringAsFixed(3)}°, ${pos.longitude.toStringAsFixed(3)}°';
      _status        = LocationStatus.success;
      notifyListeners();

      await _loadFacilities(_lat!, _lng!, isDefault: false);
    } catch (e) {
      debugPrint('❌ [LocationProvider] $e');
      await _loadFacilities(-7.2575, 112.7521, isDefault: true);
    }
  }

  // ── Step 2: Load fasilitas ─────────────────────────────────────────────────
  Future<void> _loadFacilities(double lat, double lng, {required bool isDefault}) async {
    if (isDefault) {
      _lat = lat; _lng = lng;
      _isDefault     = true;
      _locationLabel = '📍 Surabaya (default)';
      _status        = LocationStatus.failed;
    }

    // Tampilkan hardcoded DULU — UI tidak pernah kosong
    _facilities       = _hardcodedFallback(lat, lng);
    _facilitiesLoaded = true;
    _isOverpassFail   = false;
    notifyListeners();
    debugPrint('✅ [LocationProvider] Hardcoded shown (${_facilities.length} items)');

    // Coba Nominatim
    debugPrint('🔍 [LocationProvider] Trying Nominatim...');
    final nominatim = await _queryNominatim(lat, lng);
    if (nominatim != null && nominatim.isNotEmpty) {
      _facilities       = nominatim;
      _facilitiesLoaded = true;
      _isOverpassFail   = false;
      notifyListeners();
      debugPrint('✅ [LocationProvider] Nominatim: ${nominatim.length} items');
      return;
    }
    debugPrint('⚠️ [LocationProvider] Nominatim failed');

    // Coba Overpass mirror1
    final op1 = await _queryOverpass(lat, lng, 5000,
        url: 'https://overpass.kumi.systems/api/interpreter');
    if (op1 != null && op1.isNotEmpty) {
      _facilities = op1; _facilitiesLoaded = true; _isOverpassFail = false;
      notifyListeners();
      debugPrint('✅ [LocationProvider] Overpass kumi: ${op1.length} items');
      return;
    }

    // Coba Overpass mirror2
    final op2 = await _queryOverpass(lat, lng, 10000,
        url: 'https://maps.mail.ru/osm/tools/overpass/api/interpreter');
    if (op2 != null && op2.isNotEmpty) {
      _facilities = op2; _facilitiesLoaded = true; _isOverpassFail = false;
      notifyListeners();
      debugPrint('✅ [LocationProvider] Overpass mailru: ${op2.length} items');
      return;
    }

    // Semua API gagal — hardcoded tetap tampil
    _isOverpassFail = true;
    notifyListeners();
    debugPrint('ℹ️ [LocationProvider] All APIs failed, keeping hardcoded');
  }

  // ── Nominatim API — query yang BENAR ──────────────────────────────────────
  // Gunakan endpoint /search dengan tag amenity yang spesifik
  Future<List<NearbyFacility>?> _queryNominatim(double lat, double lng) async {
    try {
      final List<NearbyFacility> results = [];

      // Radius ~5km dalam derajat: ~0.045 derajat
      const delta = 0.045;
      final minLat = lat - delta;
      final maxLat = lat + delta;
      final minLng = lng - delta;
      final maxLng = lng + delta;

      // Query masing-masing tipe fasilitas dengan parameter yang benar
      // Kunci: gunakan 'amenity=[tag]' bukan 'amenity=[tag]' di viewbox saja
      final queries = [
        ('hospital', 'hospital'),
        ('pharmacy', 'pharmacy'),
        ('clinic',   'clinic'),
        ('doctors',  'doctors'),
        ('health',   'health_post'),
      ];

      for (final (typeKey, amenityTag) in queries) {
        // Nominatim: gunakan parameter 'amenity' langsung
        final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/search'
          '?format=json'
          '&addressdetails=1'
          '&limit=15'
          '&amenity=$amenityTag'
          '&viewbox=$minLng,$maxLat,$maxLng,$minLat'
          '&bounded=1',
        );

        debugPrint('🔍 Nominatim: $amenityTag');

        final resp = await http.get(uri, headers: {
          'User-Agent': 'MediHelp/1.0 (health-app)',
          'Accept-Language': 'id',
        }).timeout(const Duration(seconds: 10));

        if (resp.statusCode != 200) continue;

        final List data = json.decode(resp.body);
        debugPrint('📊 Nominatim $amenityTag: ${data.length} results');

        for (final item in data) {
          final name = _extractNominatimName(item);
          if (name.isEmpty) continue;

          final fLat  = double.tryParse(item['lat'].toString()) ?? lat;
          final fLng  = double.tryParse(item['lon'].toString()) ?? lng;
          final distM = Geolocator.distanceBetween(lat, lng, fLat, fLng);
          final tk    = _normalizeType(typeKey);

          results.add(NearbyFacility(
            name: name,
            type: tk,
            category: _categoryLabel(tk),
            address: _extractNominatimAddr(item),
            distance: distM < 1000
                ? '${distM.toStringAsFixed(0)} m'
                : '${(distM / 1000).toStringAsFixed(1)} km',
            distanceRaw: distM,
            phone: '-',
            queue: 'A-${(distM ~/ 10) % 90 + 10}',
            waitTime: '${((distM ~/ 100) % 5 + 1) * 15} menit',
            icon: _iconFor(tk),
            iconColor: _colorFor(tk),
            bgColor: _bgFor(tk),
            lat: fLat,
            lng: fLng,
          ));
        }
      }

      if (results.isEmpty) return null;
      results.sort((a, b) => a.distanceRaw.compareTo(b.distanceRaw));
      return results;
    } catch (e) {
      debugPrint('⚠️ [LocationProvider] Nominatim error: $e');
      return null;
    }
  }

  String _extractNominatimName(Map item) {
    // Prioritas: name → display_name (bagian pertama sebelum koma)
    final name = item['name'] as String? ?? '';
    if (name.isNotEmpty) return name;
    final display = item['display_name'] as String? ?? '';
    if (display.isEmpty) return '';
    final first = display.split(',').first.trim();
    // Filter: jangan tampilkan jika nama adalah nama jalan saja
    if (first.toLowerCase().startsWith('jalan') ||
        first.toLowerCase().startsWith('jl.') ||
        first.length < 3) return '';
    return first;
  }

  String _extractNominatimAddr(Map item) {
    final addr = item['address'] as Map? ?? {};
    final parts = <String>[];
    if (addr['road']       != null) parts.add(addr['road'] as String);
    if (addr['suburb']     != null) parts.add(addr['suburb'] as String);
    if (addr['city']       != null) parts.add(addr['city'] as String);
    else if (addr['town']  != null) parts.add(addr['town'] as String);
    return parts.isEmpty
        ? (item['display_name'] as String? ?? '').split(',').take(2).join(',').trim()
        : parts.join(', ');
  }

  // ── Overpass API ───────────────────────────────────────────────────────────
  Future<List<NearbyFacility>?> _queryOverpass(
      double lat, double lng, int radius, {required String url}) async {
    try {
      final query = '''
        [out:json][timeout:20];
        (
          node["amenity"="hospital"](around:$radius,$lat,$lng);
          way["amenity"="hospital"](around:$radius,$lat,$lng);
          node["amenity"="pharmacy"](around:$radius,$lat,$lng);
          way["amenity"="pharmacy"](around:$radius,$lat,$lng);
          node["amenity"="clinic"](around:$radius,$lat,$lng);
          way["amenity"="clinic"](around:$radius,$lat,$lng);
          node["amenity"="health_post"](around:$radius,$lat,$lng);
          node["amenity"="doctors"](around:$radius,$lat,$lng);
          node["amenity"="dentist"](around:$radius,$lat,$lng);
          node["healthcare"="centre"](around:$radius,$lat,$lng);
        );
        out center 60;
      ''';

      debugPrint('🔍 Overpass: $url');
      final resp = await http.post(Uri.parse(url), body: query)
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode != 200) return null;

      final elements = (json.decode(resp.body)['elements'] as List);
      final list = elements
          .where((e) => (e['tags'] ?? {})['name'] != null)
          .map((e) => _elementToFacility(e, lat, lng))
          .whereType<NearbyFacility>()
          .toList()
        ..sort((a, b) => a.distanceRaw.compareTo(b.distanceRaw));

      debugPrint('📊 Overpass result: ${list.length}');
      return list.isEmpty ? null : list;
    } catch (e) {
      debugPrint('⚠️ Overpass error: $e');
      return null;
    }
  }

  NearbyFacility? _elementToFacility(dynamic e, double uLat, double uLng) {
    final tags = e['tags'] as Map? ?? {};
    final name = tags['name'] as String? ?? '';
    if (name.isEmpty) return null;

    final fLat  = (e['lat'] ?? e['center']?['lat'] ?? uLat) as num;
    final fLng  = (e['lon'] ?? e['center']?['lon'] ?? uLng) as num;
    final distM = Geolocator.distanceBetween(uLat, uLng, fLat.toDouble(), fLng.toDouble());
    final raw   = tags['amenity'] as String? ?? tags['healthcare'] as String? ?? 'clinic';
    final tk    = _normalizeType(raw);

    return NearbyFacility(
      name: name, type: tk, category: _categoryLabel(tk),
      address: _buildAddr(tags),
      distance: distM < 1000 ? '${distM.toStringAsFixed(0)} m' : '${(distM/1000).toStringAsFixed(1)} km',
      distanceRaw: distM,
      phone: (tags['phone'] ?? tags['contact:phone'] ?? '-') as String,
      queue: 'A-${(distM ~/ 10) % 90 + 10}',
      waitTime: '${((distM ~/ 100) % 5 + 1) * 15} menit',
      icon: _iconFor(tk), iconColor: _colorFor(tk), bgColor: _bgFor(tk),
      lat: fLat.toDouble(), lng: fLng.toDouble(),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _normalizeType(String s) {
    switch (s) {
      case 'hospital':    return 'hospital';
      case 'pharmacy':    return 'pharmacy';
      case 'health_post':
      case 'health':
      case 'centre':      return 'health';
      case 'clinic':
      case 'doctors':
      case 'dentist':     return 'clinic';
      default: return s.contains('health') ? 'health' : 'clinic';
    }
  }

  String _categoryLabel(String t) {
    switch (t) {
      case 'hospital': return 'Rumah Sakit';
      case 'pharmacy': return 'Apotek';
      case 'health':   return 'Puskesmas';
      default:         return 'Klinik / Faskes';
    }
  }

  IconData _iconFor(String t) {
    switch (t) {
      case 'hospital': return Icons.local_hospital;
      case 'pharmacy': return Icons.local_pharmacy;
      case 'health':   return Icons.health_and_safety;
      default:         return Icons.medical_services;
    }
  }

  Color _colorFor(String t) {
    switch (t) {
      case 'hospital': return const Color(0xFFE53935);
      case 'pharmacy': return const Color(0xFF1E88E5);
      case 'health':   return const Color(0xFF43A047);
      default:         return const Color(0xFF8E24AA);
    }
  }

  Color _bgFor(String t) {
    switch (t) {
      case 'hospital': return const Color(0xFFFFEBEE);
      case 'pharmacy': return const Color(0xFFE3F2FD);
      case 'health':   return const Color(0xFFE8F5E9);
      default:         return const Color(0xFFF3E5F5);
    }
  }

  String _buildAddr(Map tags) {
    final p = <String>[];
    if (tags['addr:street'] != null) p.add(tags['addr:street'] as String);
    if (tags['addr:city']   != null) p.add(tags['addr:city']   as String);
    return p.isEmpty ? 'Lihat di Maps' : p.join(', ');
  }

  // ── Hardcoded fallback ─────────────────────────────────────────────────────
  List<NearbyFacility> _hardcodedFallback(double uLat, double uLng) {
    final raw = <Map<String, dynamic>>[
      // Rumah Sakit
      {'name':'RSUD Dr. Soetomo',             'address':'Jl. Mayjen Prof. Dr. Moestopo No.6-8, Surabaya','lat':-7.2636,'lng':112.7522,'phone':'031-5501080','type':'hospital'},
      {'name':'RS Islam Surabaya Ahmad Yani', 'address':'Jl. Ahmad Yani No.2-4, Wonokromo, Surabaya',    'lat':-7.3098,'lng':112.7271,'phone':'031-8281741','type':'hospital'},
      {'name':'RS William Booth Surabaya',    'address':'Jl. Diponegoro No.34, Surabaya',                'lat':-7.2658,'lng':112.7403,'phone':'031-5678917','type':'hospital'},
      {'name':'RS Darmo Surabaya',            'address':'Jl. Raya Darmo No.90, Surabaya',                'lat':-7.2907,'lng':112.7261,'phone':'031-5676253','type':'hospital'},
      // Apotek
      {'name':'Apotek K24 Ketabang',          'address':'Jl. Kaliasin No.12, Ketabang, Surabaya',        'lat':-7.2639,'lng':112.7406,'phone':'-','type':'pharmacy'},
      {'name':'Apotek Kimia Farma Raya Darmo','address':'Jl. Raya Darmo No.2, Surabaya',                 'lat':-7.2798,'lng':112.7278,'phone':'-','type':'pharmacy'},
      {'name':'Apotek K24 Wonokromo',         'address':'Jl. Raya Wonokromo No.100, Surabaya',           'lat':-7.3124,'lng':112.7346,'phone':'-','type':'pharmacy'},
      // Puskesmas
      {'name':'Puskesmas Ketintang',          'address':'Jl. Ketintang Baru No.1, Surabaya',             'lat':-7.3192,'lng':112.7230,'phone':'031-8280753','type':'health'},
      {'name':'Puskesmas Wonokromo',          'address':'Jl. Jagir Wonokromo No.100, Surabaya',          'lat':-7.3071,'lng':112.7383,'phone':'031-8494061','type':'health'},
      {'name':'Puskesmas Jagir',              'address':'Jl. Jagir Wonokromo, Surabaya',                 'lat':-7.2979,'lng':112.7468,'phone':'-','type':'health'},
      // Klinik
      {'name':'Klinik Pratama Bhakti Husada', 'address':'Jl. Karang Menjangan No.29, Surabaya',          'lat':-7.2594,'lng':112.7606,'phone':'-','type':'clinic'},
      {'name':'Klinik Utama Husada',          'address':'Jl. Raya Kupang Jaya No.2, Surabaya',           'lat':-7.2863,'lng':112.7066,'phone':'-','type':'clinic'},
      {'name':'Klinik Medika Mulia',          'address':'Jl. Margorejo Indah No.2, Surabaya',            'lat':-7.3012,'lng':112.7498,'phone':'-','type':'clinic'},
    ];

    return raw.map((r) {
      final fLat  = (r['lat'] as num).toDouble();
      final fLng  = (r['lng'] as num).toDouble();
      final distM = Geolocator.distanceBetween(uLat, uLng, fLat, fLng);
      final tk    = r['type'] as String;
      return NearbyFacility(
        name: r['name'] as String, type: tk, category: _categoryLabel(tk),
        address: r['address'] as String,
        distance: distM < 1000 ? '${distM.toStringAsFixed(0)} m' : '${(distM/1000).toStringAsFixed(1)} km',
        distanceRaw: distM, phone: r['phone'] as String,
        queue: 'A-${(distM ~/ 10) % 90 + 10}',
        waitTime: '${((distM ~/ 100) % 5 + 1) * 15} menit',
        icon: _iconFor(tk), iconColor: _colorFor(tk), bgColor: _bgFor(tk),
        lat: fLat, lng: fLng,
      );
    }).toList()..sort((a, b) => a.distanceRaw.compareTo(b.distanceRaw));
  }
}