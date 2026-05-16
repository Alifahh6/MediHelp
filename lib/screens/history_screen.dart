// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _histories = [];
  bool _isLoading = true;

  final _nameController = TextEditingController();
  final _purposeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadHistoryFromFirestore();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _loadHistoryFromFirestore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('medication_history')
          .orderBy('date', descending: true)
          .get();

      setState(() {
        _histories = snapshot.docs.map((doc) {
          final data = doc.data();
          DateTime date;
          try {
            final ts = data['date'];
            if (ts is Timestamp) {
              date = ts.toDate();
            } else {
              date = DateTime.parse(ts.toString());
            }
          } catch (_) {
            date = DateTime.now();
          }
          return {
            'id': doc.id,
            'name': data['name'] ?? '-',
            'purpose': data['purpose'] ?? '-',
            'date': date,
            'source': data['source'] ?? 'manual',
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addHistory({
    required String name,
    required String purpose,
    required DateTime date,
    String source = 'manual',
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('medication_history')
          .add({
        'name': name,
        'purpose': purpose,
        'date': Timestamp.fromDate(date),
        'source': source,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _histories.insert(0, {
          'id': docRef.id,
          'name': name,
          'purpose': purpose,
          'date': date,
          'source': source,
        });
      });
      debugPrint('✅ History saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving history: $e');
    }
  }

  Future<void> _deleteHistory(int index) async {
    final item = _histories[index];
    final docId = item['id'] as String?;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null && docId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('medication_history')
            .doc(docId)
            .delete();
        debugPrint('✅ History deleted from Firestore');
      } catch (e) {
        debugPrint('❌ Error deleting history: $e');
      }
    }
    setState(() => _histories.removeAt(index));
  }

  void _showAddSheet() {
    _nameController.clear();
    _purposeController.clear();
    _selectedDate = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            return Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tambah Riwayat Obat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nama Obat
                    Text('Nama Obat',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: textColor),
                      decoration: _inputDeco(
                          hint: 'Contoh: Amoxicillin 500mg', isDark: isDark),
                    ),
                    const SizedBox(height: 20),

                    // Kegunaan
                    Text('Kegunaan',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _purposeController,
                      style: TextStyle(color: textColor),
                      decoration: _inputDeco(
                          hint: 'Contoh: Antibiotik untuk infeksi',
                          isDark: isDark),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    // Tanggal
                    Text('Tanggal Konsumsi',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setSheet(() => _selectedDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 20, color: Color(0xFF1E88E5)),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat('dd MMMM yyyy', 'id_ID')
                                  .format(_selectedDate),
                              style: TextStyle(fontSize: 15, color: textColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_nameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nama obat wajib diisi'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          await _addHistory(
                            name: _nameController.text.trim(),
                            purpose: _purposeController.text.trim().isEmpty
                                ? '-'
                                : _purposeController.text.trim(),
                            date: _selectedDate,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Riwayat berhasil ditambahkan!'),
                                backgroundColor: Color(0xFF1E88E5),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                        ),
                        child: const Text('Simpan',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDeco({String hint = '', required bool isDark}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
        fontSize: 14,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    // Group by month
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final h in _histories) {
      final key =
          DateFormat('MMMM yyyy', 'id_ID').format(h['date'] as DateTime);
      grouped.putIfAbsent(key, () => []).add(h);
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        toolbarHeight: 56,
        title: const Text('History',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        elevation: 0,
        backgroundColor: const Color(0xFF1E88E5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadHistoryFromFirestore();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E88E5)))
          : _histories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.medication_outlined,
                            size: 64, color: Color(0xFF1E88E5)),
                      ),
                      const SizedBox(height: 20),
                      Text('Belum ada riwayat obat',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textColor)),
                      const SizedBox(height: 8),
                      Text(
                        'Tambahkan riwayat obat lewat tombol +',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, color: subColor, height: 1.5),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: 12, top: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E88E5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(entry.key,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E88E5))),
                            ],
                          ),
                        ),
                        ...entry.value.map((h) {
                          final isReminder = h['source'] == 'reminder';
                          final badgeColor = isReminder
                              ? const Color(0xFFFF9800)
                              : const Color(0xFF1E88E5);
                          final globalIndex = _histories.indexOf(h);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              leading: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  isReminder
                                      ? Icons.alarm
                                      : Icons.medication_outlined,
                                  color: badgeColor,
                                  size: 28,
                                ),
                              ),
                              title: Text(h['name'],
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textColor)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(h['purpose'],
                                      style: TextStyle(
                                          fontSize: 13, color: subColor)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_outlined,
                                          size: 12, color: subColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('dd MMM yyyy', 'id_ID')
                                            .format(h['date'] as DateTime),
                                        style: TextStyle(
                                            fontSize: 12, color: subColor),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color:
                                              badgeColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isReminder
                                              ? 'Dari Reminder'
                                              : 'Manual',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: badgeColor,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: Colors.red.shade300, size: 22),
                                onPressed: () =>
                                    _deleteHistory(globalIndex),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E88E5).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddSheet,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}