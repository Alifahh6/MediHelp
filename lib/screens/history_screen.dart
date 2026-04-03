// lib/screens/history_screen.dart
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  final List<Map<String, dynamic>> _histories = const [
    {
      'title': 'Amoxicillin 500mg',
      'type': 'Obat',
      'date': '15 Maret 2026',
      'time': '08:00',
      'status': 'Minum',
      'icon': Icons.medication,
    },
    {
      'title': 'Cek Tekanan Darah',
      'type': 'Pemeriksaan',
      'date': '14 Maret 2026',
      'time': '14:30',
      'status': 'Selesai',
      'icon': Icons.favorite,
    },
    {
      'title': 'Konsultasi Dokter',
      'type': 'Konsultasi',
      'date': '10 Maret 2026',
      'time': '10:00',
      'status': 'Selesai',
      'icon': Icons.people,
    },
    {
      'title': 'Lab Darah',
      'type': 'Laboratorium',
      'date': '7 Maret 2026',
      'time': '09:00',
      'status': 'Selesai',
      'icon': Icons.science,
    },
    {
      'title': 'Vaksin COVID-19',
      'type': 'Vaksinasi',
      'date': '1 Maret 2026',
      'time': '11:00',
      'status': 'Selesai',
      'icon': Icons.vaccines,
    },
    {
      'title': 'Paracetamol 500mg',
      'type': 'Obat',
      'date': '28 Februari 2026',
      'time': '20:00',
      'status': 'Minum',
      'icon': Icons.medication,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: const Color(0xFF1F5E7A),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Date filter
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16),
                        SizedBox(width: 8),
                        Text('Maret 2026'),
                        Spacer(),
                        Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.category, size: 16),
                        SizedBox(width: 8),
                        Text('Semua'),
                        Spacer(),
                        Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // History list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _histories.length,
              itemBuilder: (context, index) {
                final history = _histories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F5E7A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        history['icon'],
                        color: const Color(0xFF1F5E7A),
                        size: 28,
                      ),
                    ),
                    title: Text(
                      history['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${history['date']} • ${history['time']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: history['status'] == 'Selesai'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            history['status'],
                            style: TextStyle(
                              fontSize: 10,
                              color: history['status'] == 'Selesai'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Detail: ${history['title']}'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}