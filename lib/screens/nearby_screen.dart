// lib/screens/nearby_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:medi_help/providers/location_provider.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final MapController _mapController = MapController();
  String _activeFilter = 'ALL';

  final List<Map<String, dynamic>> _filters = [
    {'key': 'ALL',      'label': 'Semua',      'icon': Icons.apps_outlined},
    {'key': 'hospital', 'label': 'Rumah Sakit', 'icon': Icons.local_hospital},
    {'key': 'pharmacy', 'label': 'Apotek',      'icon': Icons.local_pharmacy},
    {'key': 'health',   'label': 'Puskesmas',   'icon': Icons.health_and_safety},
    {'key': 'clinic',   'label': 'Faskes',      'icon': Icons.medical_services},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().init();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<NearbyFacility> _filtered(List<NearbyFacility> all) {
    if (_activeFilter == 'ALL') return all;
    if (_activeFilter == 'clinic') {
      return all.where((f) => f.type == 'clinic' || f.type == 'doctors' || f.type == 'dentist').toList();
    }
    return all.where((f) => f.type == _activeFilter).toList();
  }

  int _count(List<NearbyFacility> all, String key) {
    if (key == 'ALL') return all.length;
    if (key == 'clinic') return all.where((f) => f.type == 'clinic' || f.type == 'doctors').length;
    return all.where((f) => f.type == key).length;
  }

  void _moveMapToUser(LocationProvider loc) {
    if (!loc.hasLocation) return;
    try { _mapController.move(LatLng(loc.lat!, loc.lng!), 14); } catch (_) {}
  }

  Future<void> _openDirections(NearbyFacility f) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${f.lat},${f.lng}&travelmode=driving');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka Google Maps')));
    }
  }

  void _showDetail(NearbyFacility f) {
    _saveVisit(f);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FacilityBottomSheet(
        facility: f, markerColor: f.iconColor, isDark: isDark,
        onDirections: () { Navigator.pop(context); _openDirections(f); },
        onGetQueue:   () { Navigator.pop(context); Navigator.pushNamed(context, '/queue'); },
      ),
    );
  }

  Future<void> _saveVisit(NearbyFacility f) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance.collection('users').doc(uid).collection('activities').add({
        'type': 'visit', 'title': 'Kunjungan ke ${f.name}',
        'facilityName': f.name, 'facilityAddress': f.address,
        'distance': f.distance, 'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'hospital': return Icons.local_hospital;
      case 'pharmacy': return Icons.local_pharmacy;
      case 'health':   return Icons.health_and_safety;
      default:         return Icons.medical_services;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);

    return Consumer<LocationProvider>(builder: (context, loc, _) {
      final userLL   = loc.hasLocation ? LatLng(loc.lat!, loc.lng!) : const LatLng(-7.2575, 112.7521);
      final filtered = _filtered(loc.facilities);

      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        appBar: AppBar(
          toolbarHeight: 56,
          title: const Text('Fasilitas Terdekat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          elevation: 0, backgroundColor: const Color(0xFF1E88E5),
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => loc.refresh())],
        ),
        body: Column(children: [

          // ── Status bar ─────────────────────────────────────────
          // GPS gagal → pakai data default Surabaya
          if (loc.isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFFF3E0),
              child: Row(children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(child: Text('GPS tidak aktif – menampilkan area Surabaya (default).',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800))),
              ]),
            ),
          // Overpass gagal tapi data hardcoded tetap tampil
          if (loc.isOverpassFail && loc.facilities.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFFF8E1),
              child: Row(children: [
                Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
                const SizedBox(width: 8),
                Expanded(child: Text('Data dari server tidak tersedia, menampilkan data umum.',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade800))),
                GestureDetector(
                  onTap: () => loc.refresh(),
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text('Refresh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                  ),
                ),
              ]),
            ),
          // GPS berhasil & data tersedia
          if (!loc.isDefault && loc.hasLocation && !loc.isOverpassFail)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFE8F5E9),
              child: Row(children: [
                Icon(Icons.location_on, size: 16, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text('Lokasi: ${loc.lat!.toStringAsFixed(4)}°, ${loc.lng!.toStringAsFixed(4)}°',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
              ]),
            ),

          // ── Peta ───────────────────────────────────────────────
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.33,
            child: Stack(children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: userLL, initialZoom: 14,
                  onMapReady: () => Future.delayed(const Duration(milliseconds: 300), () => _moveMapToUser(loc)),
                ),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.medi_help'),
                  // Marker user
                  MarkerLayer(markers: [
                    Marker(point: userLL, width: 44, height: 44,
                      child: Container(
                        decoration: BoxDecoration(color: const Color(0xFF1E88E5), shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)]),
                        child: const Icon(Icons.person_pin, color: Colors.white, size: 22),
                      )),
                  ]),
                  // Semua marker fasilitas (tampilkan semua agar terlihat di peta)
                  MarkerLayer(markers: loc.facilities.map((f) => Marker(
                    point: LatLng(f.lat, f.lng), width: 36, height: 36,
                    child: GestureDetector(
                      onTap: () => _showDetail(f),
                      child: Container(
                        decoration: BoxDecoration(color: f.iconColor, shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: f.iconColor.withOpacity(0.4), blurRadius: 6)]),
                        child: Icon(_iconFor(f.type), color: Colors.white, size: 16),
                      ),
                    ),
                  )).toList()),
                ],
              ),
              if (loc.isLoading)
                Container(color: Colors.white.withOpacity(0.7),
                  child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(color: Color(0xFF1E88E5)),
                    SizedBox(height: 8),
                    Text('Mencari fasilitas…', style: TextStyle(fontSize: 13, color: Color(0xFF1E88E5))),
                  ]))),
              Positioned(bottom: 12, right: 12,
                child: FloatingActionButton.small(
                  heroTag: 'nearbyLoc', onPressed: () => _moveMapToUser(loc),
                  backgroundColor: Colors.white, elevation: 4,
                  child: const Icon(Icons.my_location, color: Color(0xFF1E88E5)),
                )),
            ]),
          ),

          // ── Filter chips dengan badge jumlah ───────────────────
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _filters.map((f) {
                final isActive = _activeFilter == f['key'];
                final cnt = loc.isLoading ? 0 : _count(loc.facilities, f['key'] as String);
                return GestureDetector(
                  onTap: () => setState(() => _activeFilter = f['key'] as String),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF1E88E5) : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: isActive ? const Color(0xFF1E88E5) : (isDark ? Colors.white12 : Colors.grey.shade300)),
                    ),
                    child: Row(children: [
                      Icon(f['icon'] as IconData, size: 15,
                          color: isActive ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                      const SizedBox(width: 5),
                      Text(f['label'] as String,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700))),
                      const SizedBox(width: 5),
                      // Badge jumlah
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white.withOpacity(0.25) : const Color(0xFF1E88E5).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$cnt', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : const Color(0xFF1E88E5))),
                      ),
                    ]),
                  ),
                );
              }).toList()),
            ),
          ),

          // ── Header list ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(children: [
              Container(width: 4, height: 18,
                  decoration: BoxDecoration(color: const Color(0xFF1E88E5), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(
                _activeFilter == 'ALL' ? 'Semua Fasilitas'
                    : _filters.firstWhere((f) => f['key'] == _activeFilter)['label'] as String,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
              ),
              const Spacer(),
              if (!loc.isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF1E88E5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('${filtered.length} tempat',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E88E5))),
                ),
            ]),
          ),

          // ── List ───────────────────────────────────────────────
          Expanded(
            child: loc.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)))
                : filtered.isEmpty
                    ? _emptyState(loc)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final f = filtered[i];
                          return _FacilityCard(
                            facility: f, color: f.iconColor, icon: _iconFor(f.type), isDark: isDark,
                            onTap: () => _showDetail(f), onDirections: () => _openDirections(f),
                          );
                        }),
          ),
        ]),
      );
    });
  }

  Widget _emptyState(LocationProvider loc) {
    // Jika Overpass gagal (bukan sekadar filter kosong)
    if (loc.isOverpassFail) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.wifi_off, size: 64, color: Colors.orange)),
        const SizedBox(height: 20),
        const Text('Gagal mengambil data fasilitas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Periksa koneksi internet lalu refresh', style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => loc.refresh(),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Coba Lagi'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5), foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ]));
    }
    // Filter aktif tapi 0 hasil
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF1E88E5).withOpacity(0.08), shape: BoxShape.circle),
          child: const Icon(Icons.local_hospital_outlined, size: 64, color: Color(0xFF1E88E5))),
      const SizedBox(height: 20),
      const Text('Tidak ada fasilitas ditemukan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text('Coba filter lain atau refresh', style: TextStyle(color: Colors.grey, fontSize: 14)),
    ]));
  }
}

// ── Facility Card ─────────────────────────────────────────────────────────────
class _FacilityCard extends StatelessWidget {
  final NearbyFacility facility;
  final Color color;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDirections;
  const _FacilityCard({required this.facility, required this.color, required this.icon, required this.isDark, required this.onTap, required this.onDirections});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final subColor  = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 48, height: 48,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: color, size: 26)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(facility.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.location_on, size: 12, color: subColor), const SizedBox(width: 4),
                  Expanded(child: Text(facility.address, style: TextStyle(fontSize: 12, color: subColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ])),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _badge(Icons.near_me_outlined, facility.distance, color),
              const SizedBox(width: 8),
              _badge(Icons.category_outlined, facility.category, color),
            ]),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDirections,
                icon: const Icon(Icons.directions, size: 16), label: const Text('Petunjuk Arah'),
                style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF1E88E5),
                    side: const BorderSide(color: Color(0xFF1E88E5)), padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              )),
          ]),
        ),
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color), const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]));
}

// ── Bottom Sheet ──────────────────────────────────────────────────────────────
class _FacilityBottomSheet extends StatelessWidget {
  final NearbyFacility facility;
  final Color markerColor;
  final bool isDark;
  final VoidCallback onDirections;
  final VoidCallback onGetQueue;
  const _FacilityBottomSheet({required this.facility, required this.markerColor, required this.isDark, required this.onDirections, required this.onGetQueue});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final subColor  = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Row(children: [
          Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: markerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.local_hospital, color: markerColor, size: 28)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(facility.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
            Text(facility.category, style: TextStyle(fontSize: 13, color: markerColor, fontWeight: FontWeight.w600)),
          ])),
        ]),
        const SizedBox(height: 20),
        Divider(color: isDark ? Colors.white12 : Colors.grey.shade200),
        const SizedBox(height: 16),
        _row(Icons.place_outlined,   'Alamat',   facility.address,                                        textColor, subColor),
        const SizedBox(height: 10),
        _row(Icons.near_me_outlined, 'Jarak',    facility.distance,                                       textColor, subColor),
        const SizedBox(height: 10),
        _row(Icons.phone_outlined,   'Telepon',  facility.phone == '-' ? 'Tidak tersedia' : facility.phone, textColor, subColor),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: ElevatedButton.icon(
            onPressed: onDirections,
            icon: const Icon(Icons.directions, size: 18), label: const Text('Petunjuk Arah'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(
            onPressed: onGetQueue,
            icon: const Icon(Icons.queue, size: 18), label: const Text('Ambil Antrian'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF43A047), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0))),
        ]),
      ]),
    );
  }

  Widget _row(IconData icon, String label, String value, Color tc, Color sc) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: const Color(0xFF1E88E5)), const SizedBox(width: 10),
        SizedBox(width: 70, child: Text('$label:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sc))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: tc))),
      ]);
}