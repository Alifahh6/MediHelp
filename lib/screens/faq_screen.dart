// lib/screens/faq_screen.dart
import 'package:flutter/material.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'Bagaimana cara menggunakan fitur antrian online?',
      'answer': 'Anda dapat menggunakan fitur Take Queue di halaman utama. Pilih rumah sakit, poli, tanggal, dan waktu kunjungan, lalu klik Take Queue untuk mendapatkan nomor antrian.',
      'category': 'Fitur',
    },
    {
      'question': 'Bagaimana cara menemukan fasilitas kesehatan terdekat?',
      'answer': 'Pengguna dapat menggunakan fitur Nearby untuk mencari fasilitas kesehatan terdekat. Sistem akan menampilkan daftar rumah sakit, klinik, puskesmas terdekat berdasarkan lokasi pengguna.',
      'category': 'Fitur',
    },
    {
      'question': 'Apa fungsi fitur riwayat obat?',
      'answer': 'Fitur riwayat obat membantu Anda mencatat dan melacak riwayat konsumsi obat, termasuk dosis, waktu, dan durasi pengobatan.',
      'category': 'Fitur',
    },
    {
      'question': 'Bagaimana cara menyimpan dokumen medis di aplikasi?',
      'answer': 'Anda dapat menyimpan dokumen medis melalui fitur Records. Klik tombol + dan pilih file dari galeri atau kamera untuk mengunggah dokumen medis Anda.',
      'category': 'Records',
    },
    {
      'question': 'Bagaimana cara mengatur pengingat minum obat?',
      'answer': 'Gunakan fitur Reminder. Klik tombol +, masukkan nama obat, aturan minum, waktu (pagi/siang/malam), dan durasi. Aplikasi akan mengingatkan Anda sesuai jadwal.',
      'category': 'Reminder',
    },
    {
      'question': 'Apakah data kesehatan pengguna aman?',
      'answer': 'Ya, MediHelp menjaga keamanan data pengguna dengan enkripsi dan tidak membagikan data pribadi Anda ke pihak ketiga tanpa izin.',
      'category': 'Keamanan',
    },
    {
      'question': 'Apakah saya bisa mengubah atau menghapus data yang telah disimpan?',
      'answer': 'Ya, Anda dapat mengedit atau menghapus data kesehatan, riwayat obat, dan dokumen medis kapan saja melalui menu yang tersedia di setiap fitur.',
      'category': 'Pengaturan',
    },
    {
      'question': 'Apakah MediHelp dapat menggantikan konsultasi dengan dokter?',
      'answer': 'Tidak. MediHelp hanya berfungsi sebagai aplikasi pendukung untuk membantu pengguna mengelola informasi kesehatan dan mengakses layanan kesehatan. Untuk diagnosis dan pengobatan, pengguna tetap perlu berkonsultasi langsung dengan tenaga medis.',
      'category': 'Penting',
    },
  ];

  List<Map<String, dynamic>> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqs;
    return _faqs.where((faq) {
      return faq['question'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             faq['answer'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Frequently Asked Questions'),
        backgroundColor: const Color(0xFF1F5E7A),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          
          // FAQ List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredFaqs.length,
              itemBuilder: (context, index) {
                final faq = _filteredFaqs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F5E7A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.help_outline,
                        color: Color(0xFF1F5E7A),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      faq['question'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F5E7A).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                faq['category'],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF1F5E7A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              faq['answer'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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