// lib/screens/reminder_screen.dart
import 'package:flutter/material.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final List<Map<String, dynamic>> _reminders = [
    {
      'name': 'Methylprednisolone 4mg',
      'frequency': '3x sehari',
      'times': ['Pagi', 'Siang', 'Malam'],
      'rules': 'Setiap 8 jam sekali',
      'days': '7 Hari',
    },
    {
      'name': 'Amoxicillin 500mg',
      'frequency': '2x sehari',
      'times': ['Pagi', 'Malam'],
      'rules': 'Setelah Makan',
      'days': '5 Hari',
    },
    {
      'name': 'Paracetamol 500mg',
      'frequency': 'Sesuai kebutuhan',
      'times': ['Pagi'],
      'rules': 'Jika demam',
      'days': '-',
    },
  ];

  void _showAddReminderDialog() {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController();
    final _rulesController = TextEditingController();
    final _daysController = TextEditingController();
    bool _morning = false;
    bool _afternoon = false;
    bool _evening = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Add Reminder'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Obat',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama obat tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text('Waktu'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilterChip(
                              label: const Text('Pagi'),
                              selected: _morning,
                              onSelected: (selected) {
                                setStateDialog(() {
                                  _morning = selected;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilterChip(
                              label: const Text('Siang'),
                              selected: _afternoon,
                              onSelected: (selected) {
                                setStateDialog(() {
                                  _afternoon = selected;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilterChip(
                              label: const Text('Malam'),
                              selected: _evening,
                              onSelected: (selected) {
                                setStateDialog(() {
                                  _evening = selected;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _rulesController,
                        decoration: const InputDecoration(
                          labelText: 'Aturan Minum',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _daysController,
                        decoration: const InputDecoration(
                          labelText: 'Berapa Hari?',
                          border: OutlineInputBorder(),
                          suffixText: 'Hari',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Kegunaan',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reminder berhasil ditambahkan')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F5E7A),
                  ),
                  child: const Text('Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Reminder'),
        backgroundColor: const Color(0xFF1F5E7A),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddReminderDialog,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reminders.length,
        itemBuilder: (context, index) {
          final reminder = _reminders[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F5E7A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medication,
                          color: Color(0xFF1F5E7A),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reminder['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${reminder['frequency']} - ${reminder['rules']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: true,
                        onChanged: (value) {},
                        activeColor: const Color(0xFF1F5E7A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: (reminder['times'] as List<String>).map((time) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          time,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                  if (reminder['days'] != '-')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Durasi: ${reminder['days']}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReminderDialog,
        backgroundColor: const Color(0xFF1F5E7A),
        child: const Icon(Icons.add),
      ),
    );
  }
}