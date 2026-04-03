// lib/screens/records_screen.dart
import 'package:flutter/material.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  final List<Map<String, dynamic>> _records = const [
    {
      'title': 'Lab Results 2026',
      'date': 'Uploaded: 7 march 2026',
      'type': 'Laboratorium',
      'icon': Icons.biotech,
    },
    {
      'title': 'Medical Checkup',
      'date': 'Uploaded: 1 february 2026',
      'type': 'Kesehatan Umum',
      'icon': Icons.health_and_safety,
    },
    {
      'title': 'Vaccination Record',
      'date': 'Uploaded: 15 january 2026',
      'type': 'Vaksinasi',
      'icon': Icons.vaccines,
    },
    {
      'title': 'Dental Checkup',
      'date': 'Uploaded: 20 december 2025',
      'type': 'Gigi',
      'icon': Icons.medical_services,
    },
    {
      'title': 'Blood Test Results',
      'date': 'Uploaded: 10 december 2025',
      'type': 'Laboratorium',
      'icon': Icons.science,
    },
    {
      'title': 'X-Ray Results',
      'date': 'Uploaded: 5 november 2025',
      'type': 'Radiologi',
      'icon': Icons.image,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Medical Records'),
        backgroundColor: const Color(0xFF1F5E7A),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.filter_list, size: 20),
                        SizedBox(width: 8),
                        Text('Filter'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.sort, size: 20),
                        SizedBox(width: 8),
                        Text('Sort'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Records list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final record = _records[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F5E7A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        record['icon'],
                        color: const Color(0xFF1F5E7A),
                        size: 28,
                      ),
                    ),
                    title: Text(
                      record['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          record['date'],
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
                            color: const Color(0xFF1F5E7A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            record['type'],
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF1F5E7A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Membuka ${record['title']}'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload dokumen medis')),
          );
        },
        backgroundColor: const Color(0xFF1F5E7A),
        child: const Icon(Icons.add),
      ),
    );
  }
}