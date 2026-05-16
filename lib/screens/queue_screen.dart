// lib/screens/queue_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medi_help/providers/location_provider.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _patientNameController = TextEditingController();
  String _searchQuery = '';
  NearbyFacility? _selectedHospital;
  String? _selectedPoly;
  DateTime? _selectedDate;
  String? _selectedTime;

  final List<String> _polys = [
    'Umum', 'Gigi', 'Kandungan', 'Anak', 'Mata', 'THT', 'Jantung', 'Ortopedi',
  ];
  final List<String> _timeSlots = [
    '07.00', '08.00', '09.00', '10.00', '11.00',
    '12.00', '13.00', '14.00', '15.00', '16.00',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pastikan data lokasi sudah tersedia (jika belum, minta load)
      context.read<LocationProvider>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _patientNameController.dispose();
    super.dispose();
  }

  List<NearbyFacility> _filteredHospitals(List<NearbyFacility> all) {
    // Queue screen hanya tampilkan rumah sakit (hospital)
    final hospitals = all.where((f) => f.type == 'hospital').toList();
    if (_searchQuery.isEmpty) return hospitals;
    return hospitals.where((h) =>
        h.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        h.address.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  void _showRegisterSheet(NearbyFacility hospital) {
    _selectedHospital = hospital;
    _patientNameController.clear();
    _selectedPoly = null;
    _selectedDate = null;
    _selectedTime = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheet) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
          final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
          final inputFill = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Daftar Antrian',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Icon(Icons.local_hospital, color: Color(0xFF1E88E5), size: 32),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(hospital.name,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                      const SizedBox(height: 4),
                      Text('Antrian: ${hospital.queue} • ${hospital.waitTime}',
                          style: TextStyle(fontSize: 13, color: subColor)),
                    ])),
                  ]),
                ),
                const SizedBox(height: 24),

                // Nama Pasien
                Text('Nama Pasien',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 8),
                TextField(
                  controller: _patientNameController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Masukkan nama lengkap',
                    hintStyle: TextStyle(color: subColor),
                    filled: true, fillColor: inputFill,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 20),

                // Jenis Layanan
                Text('Jenis Layanan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonFormField<String>(
                    value: _selectedPoly,
                    dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                    style: TextStyle(color: textColor, fontSize: 14),
                    decoration: const InputDecoration(border: InputBorder.none),
                    hint: Text('Pilih poli', style: TextStyle(color: subColor)),
                    items: _polys.map((p) => DropdownMenuItem(
                        value: p, child: Text(p, style: TextStyle(color: textColor)))).toList(),
                    onChanged: (v) => setSheet(() => _selectedPoly = v),
                  ),
                ),
                const SizedBox(height: 20),

                // Tanggal
                Text('Tanggal Kunjungan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) setSheet(() => _selectedDate = date);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF1E88E5)),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate!)
                            : 'Pilih tanggal',
                        style: TextStyle(color: _selectedDate != null ? textColor : subColor),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // Waktu
                Text('Waktu',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: _timeSlots.map((t) {
                    final selected = _selectedTime == t;
                    return GestureDetector(
                      onTap: () => setSheet(() => _selectedTime = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFF1E88E5) : inputFill,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Text(t, style: TextStyle(
                            color: selected ? Colors.white : textColor,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () => _submitQueue(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: const Text('Daftar',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          );
        });
      },
    );
  }

  Future<void> _submitQueue(BuildContext sheetContext) async {
    if (_patientNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama pasien wajib diisi')));
      return;
    }
    if (_selectedPoly == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih jenis layanan')));
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih tanggal kunjungan')));
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih waktu kunjungan')));
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      Navigator.pop(sheetContext);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login terlebih dahulu'),
              backgroundColor: Colors.orange));
      return;
    }

    try {
      final h = _selectedHospital!;
      await FirebaseFirestore.instance
          .collection('users').doc(userId).collection('queues').add({
        'facilityName': h.name,
        'facilityAddress': h.address,
        'queueNumber': h.queue,
        'waitTime': h.waitTime,
        'patientName': _patientNameController.text,
        'poly': _selectedPoly,
        'date': _selectedDate!.toIso8601String(),
        'time': _selectedTime,
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance
          .collection('users').doc(userId).collection('activities').add({
        'type': 'queue',
        'title': 'Ambil antrian di ${h.name}',
        'description': 'No. Antrian: ${h.queue} | Poli: $_selectedPoly',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ Failed to save queue: $e');
    }

    Navigator.pop(sheetContext);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E88E5).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Color(0xFF1E88E5), size: 48)),
          const SizedBox(height: 16),
          const Text('Antrian Berhasil!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_selectedHospital!.name, textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('No. Antrian: ${_selectedHospital!.queue}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
          const SizedBox(height: 4),
          Text('$_selectedPoly • ${DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDate!)} • $_selectedTime',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('Estimasi: ${_selectedHospital!.waitTime}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ]),
        actions: [
          Center(child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return Consumer<LocationProvider>(
      builder: (context, loc, _) {
        final hospitals = _filteredHospitals(loc.facilities);

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
          appBar: AppBar(
            toolbarHeight: 56,
            title: const Text('Take Queue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            elevation: 0,
            backgroundColor: const Color(0xFF1E88E5),
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context)),
            actions: [
              IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => loc.refresh()),
            ],
          ),
          body: Column(children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  Icon(Icons.search, color: subColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor),
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                        hintText: 'Cari rumah sakit...',
                        hintStyle: TextStyle(fontSize: 14, color: subColor),
                        border: InputBorder.none, isDense: true),
                  )),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                      child: Icon(Icons.close, color: subColor, size: 20),
                    ),
                ]),
              ),
            ),

            // Status bar
            if (loc.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E88E5))),
                    const SizedBox(width: 10),
                    Text('Mendeteksi lokasi dan mencari RS terdekat...',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade800)),
                  ]),
                ),
              ),

            if (!loc.isLoading && loc.isDefault)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      'GPS tidak aktif, menampilkan RS default (Surabaya).',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                    )),
                  ]),
                ),
              ),

            if (!loc.isLoading && !loc.isDefault && loc.hasLocation)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(Icons.location_on, size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 10),
                    Text('Menampilkan RS terdekat dari lokasi kamu',
                        style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
                  ]),
                ),
              ),

            const SizedBox(height: 8),

            // List RS
            Expanded(
              child: loc.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)))
                  : hospitals.isEmpty
                      ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF1E88E5).withOpacity(0.08), shape: BoxShape.circle),
                              child: const Icon(Icons.local_hospital_outlined, size: 64, color: Color(0xFF1E88E5))),
                          const SizedBox(height: 20),
                          Text('Tidak ada rumah sakit ditemukan',
                              style: TextStyle(fontSize: 16, color: subColor)),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: hospitals.length,
                          itemBuilder: (context, index) =>
                              _buildHospitalCard(hospitals[index], isDark, textColor, subColor),
                        ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildHospitalCard(NearbyFacility hospital, bool isDark, Color textColor, Color subColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.local_hospital, color: Color(0xFF1E88E5), size: 28)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hospital.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
              const SizedBox(height: 4),
              Text(hospital.address,
                  style: TextStyle(fontSize: 13, color: subColor),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _infoBadge(Icons.place_outlined, hospital.distance, Colors.blue),
            const SizedBox(width: 8),
            _infoBadge(Icons.access_time_outlined, hospital.waitTime, Colors.orange),
            const SizedBox(width: 8),
            _infoBadge(Icons.confirmation_number_outlined, hospital.queue, Colors.green),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showRegisterSheet(hospital),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: const Text('Take Queue',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}