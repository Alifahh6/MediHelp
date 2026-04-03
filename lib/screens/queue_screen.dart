// lib/screens/queue_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  String? _selectedHospital;
  String? _selectedPoly;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _patientNameController = TextEditingController();

  final List<String> _hospitals = [
    'Rumah Sakit Islam Surabaya',
    'Rumah Sakit Darmo',
    'Royal Hospital Surabaya',
    'Rumah Sakit Umum Daerah',
  ];

  final List<String> _polys = [
    'Umum',
    'Gigi',
    'Kandungan',
    'Anak',
    'Mata',
    'THT',
  ];

  final List<Map<String, dynamic>> _queues = [
    {
      'hospital': 'Rumah Sakit Islam Surabaya',
      'queue': 'A-25',
      'waitTime': '30 menit',
    },
    {
      'hospital': 'Rumah Sakit Darmo',
      'queue': 'A-26',
      'waitTime': '40 menit',
    },
    {
      'hospital': 'Royal Hospital Surabaya',
      'queue': 'A-30',
      'waitTime': '80 menit',
    },
  ];

  @override
  void dispose() {
    _patientNameController.dispose();
    super.dispose();
  }

  void _submitQueue() {
    if (_patientNameController.text.isEmpty ||
        _selectedHospital == null ||
        _selectedPoly == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua data')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Antrian berhasil diambil di $_selectedHospital',
        ),
      ),
    );

    // reset form
    setState(() {
      _patientNameController.clear();
      _selectedHospital = null;
      _selectedPoly = null;
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Take Queue'),
        backgroundColor: const Color(0xFF1F5E7A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// FORM
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Form Pengambilan Antrian',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Nama Pasien
                    TextFormField(
                      controller: _patientNameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Pasien',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Rumah Sakit
                    DropdownButtonFormField<String>(
                      initialValue: _selectedHospital,
                      decoration: InputDecoration(
                        labelText: 'Rumah Sakit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.local_hospital),
                      ),
                      items: _hospitals.map((hospital) {
                        return DropdownMenuItem(
                          value: hospital,
                          child: Text(hospital),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedHospital = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    /// Jenis Layanan
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPoly,
                      decoration: InputDecoration(
                        labelText: 'Jenis Layanan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.medical_services),
                      ),
                      items: _polys.map((poly) {
                        return DropdownMenuItem(
                          value: poly,
                          child: Text(poly),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPoly = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    /// Tanggal
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 30)),
                        );

                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Tanggal Kunjungan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? DateFormat('dd/MM/yyyy')
                                  .format(_selectedDate!)
                              : 'Pilih Tanggal',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Waktu
                    InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );

                        if (time != null) {
                          setState(() {
                            _selectedTime = time;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Waktu',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.access_time),
                        ),
                        child: Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Pilih Waktu',
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitQueue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F5E7A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Take Queue',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// LIST ANTRIAN
            const Text(
              'Antrian Tersedia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ..._queues.map((queue) => _buildQueueCard(queue)),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueCard(Map<String, dynamic> queue) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF1F5E7A).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  queue['queue'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1F5E7A),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    queue['hospital'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Waktu Menunggu: ${queue['waitTime']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Mengambil antrian ${queue['queue']} di ${queue['hospital']}'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F5E7A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Take'),
            ),
          ],
        ),
      ),
    );
  }
}