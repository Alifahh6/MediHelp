// lib/screens/faq_screen.dart
import 'package:flutter/material.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  final List<Map<String, String>> _faqs = [
    {'question': 'Apa itu MediHelp?', 'answer': 'MediHelp adalah aplikasi kesehatan digital yang membantu kamu menemukan fasilitas kesehatan terdekat, mengambil antrian online, mencatat riwayat pengobatan, dan mengatur pengingat minum obat.'},
    {'question': 'Bagaimana cara mengambil antrian?', 'answer': 'Buka menu "Antrian" di halaman utama, pilih rumah sakit terdekat, pilih poli dan waktu kunjungan, lalu tekan tombol "Daftar". Nomor antrian akan langsung keluar.'},
    {'question': 'Apakah data saya aman?', 'answer': 'Ya, seluruh data kamu disimpan secara aman menggunakan Firebase dengan enkripsi. Hanya kamu yang bisa mengakses data pribadimu.'},
    {'question': 'Bagaimana cara mengatur pengingat obat?', 'answer': 'Masuk ke menu "Pengingat", tekan tombol +, isi nama obat, pilih waktu minum (Pagi/Siang/Malam), dan tentukan durasi. Notifikasi akan otomatis muncul sesuai jadwal.'},
    {'question': 'Apakah bisa login dengan Google?', 'answer': 'Ya! MediHelp mendukung login dengan akun Google. Tekan tombol "G" di halaman login atau register untuk masuk dengan mudah.'},
    {'question': 'Bagaimana cara menyimpan rekam medis?', 'answer': 'Buka menu "Rekam Medis", tekan tombol +, pilih file dari penyimpanan atau ambil foto dokumen. File akan tersimpan dan bisa diakses kapan saja.'},
    {'question': 'Apakah bisa menggunakan aplikasi tanpa login?', 'answer': 'Kamu bisa melihat halaman utama dan informasi fasilitas kesehatan tanpa login. Namun untuk fitur antrian, reminder, rekam medis, dan riwayat, kamu perlu login terlebih dahulu.'},
    {'question': 'Mengapa GPS tidak terdeteksi?', 'answer': 'Pastikan GPS sudah aktif di pengaturan HP dan izin lokasi sudah diberikan ke aplikasi MediHelp. Buka Pengaturan > Aplikasi > MediHelp > Izin > Lokasi > Izinkan setiap saat.'},
    {'question': 'Bagaimana cara mengganti tema gelap?', 'answer': 'Buka halaman Profil, temukan menu "Dark Mode" dan aktifkan toggle-nya. Tema akan berubah secara instan di seluruh aplikasi.'},
    {'question': 'Bagaimana cara menghubungi support?', 'answer': 'Untuk saat ini, MediHelp masih dalam tahap pengembangan. Jika ada masukan atau kendala, kamu bisa menghubungi tim pengembang melalui email yang tersedia di profil aplikasi.'},
  ];

  late List<bool> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = List.generate(_faqs.length, (_) => false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return List.generate(_faqs.length, (i) => {'faq': _faqs[i], 'idx': i});
    final q = _query.toLowerCase();
    return [
      for (int i = 0; i < _faqs.length; i++)
        if (_faqs[i]['question']!.toLowerCase().contains(q) || _faqs[i]['answer']!.toLowerCase().contains(q))
          {'faq': _faqs[i], 'idx': i}
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final subColor  = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final filtered  = _filtered;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: Column(children: [

        // ── Search bar ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: cardColor, borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              Icon(Icons.search, color: subColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(color: textColor, fontSize: 14),
                  onChanged: (v) => setState(() {
                    _query = v;
                    // Otomatis buka semua jawaban saat mencari
                    if (v.isNotEmpty) _expanded = List.generate(_faqs.length, (_) => true);
                  }),
                  decoration: InputDecoration(
                    hintText: 'Cari pertanyaan...',
                    hintStyle: TextStyle(color: subColor, fontSize: 14),
                    border: InputBorder.none, isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_query.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() {
                    _searchCtrl.clear(); _query = '';
                    _expanded = List.generate(_faqs.length, (_) => false);
                  }),
                  child: Icon(Icons.close, color: subColor, size: 20),
                ),
            ]),
          ),
        ),

        // ── Content ─────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              // Header banner — sembunyikan saat search aktif
              if (_query.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.help_outline, color: Colors.white, size: 24)),
                    const SizedBox(width: 14),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Pertanyaan Umum', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(height: 4),
                      Text('Temukan jawaban atas pertanyaanmu di sini', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ])),
                  ]),
                ),
              ],

              // Tidak ada hasil
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Column(children: [
                    Container(padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: const Color(0xFF1E88E5).withOpacity(0.08), shape: BoxShape.circle),
                        child: const Icon(Icons.search_off, size: 52, color: Color(0xFF1E88E5))),
                    const SizedBox(height: 16),
                    Text('Pertanyaan tidak ditemukan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 8),
                    Text('Coba kata kunci lain', style: TextStyle(fontSize: 13, color: subColor)),
                  ]),
                ),

              // FAQ items
              ...filtered.map((item) {
                final faq    = item['faq'] as Map<String, String>;
                final idx    = item['idx'] as int;
                final isOpen = _expanded[idx];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cardColor, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _expanded[idx] = !isOpen),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(width: 28, height: 28,
                                  decoration: BoxDecoration(color: const Color(0xFF1E88E5).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Center(child: Text('${idx + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))))),
                              const SizedBox(width: 12),
                              Expanded(child: _highlight(faq['question']!, _query, textColor, isBold: true)),
                              Icon(isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF1E88E5), size: 22),
                            ]),
                            if (isOpen) ...[
                              const SizedBox(height: 12),
                              Container(width: double.infinity, height: 1, color: isDark ? Colors.white12 : Colors.grey.shade200),
                              const SizedBox(height: 12),
                              _highlight(faq['answer']!, _query, subColor),
                            ],
                          ]),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),
              Center(child: Text('MediHelp v1.0 — Dibuat untuk kemudahan kesehatan kamu',
                  style: TextStyle(fontSize: 11, color: subColor), textAlign: TextAlign.center)),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ]),
    );
  }

  // Highlight teks yang cocok dengan kata kunci pencarian
  Widget _highlight(String text, String query, Color defaultColor, {bool isBold = false}) {
    if (query.isEmpty) {
      return Text(text, style: TextStyle(fontSize: isBold ? 14 : 13,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal, color: defaultColor, height: 1.6));
    }
    final lower = text.toLowerCase();
    final q     = query.toLowerCase();
    final spans = <TextSpan>[];
    int start   = 0;

    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start),
            style: TextStyle(fontSize: isBold ? 14 : 13,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal, color: defaultColor, height: 1.6)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx),
            style: TextStyle(fontSize: isBold ? 14 : 13,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal, color: defaultColor, height: 1.6)));
      }
      spans.add(TextSpan(text: text.substring(idx, idx + query.length),
          style: TextStyle(fontSize: isBold ? 14 : 13, height: 1.6,
              color: const Color(0xFF1565C0), fontWeight: FontWeight.bold,
              backgroundColor: const Color(0xFFBBDEFB))));
      start = idx + query.length;
    }
    return RichText(text: TextSpan(children: spans));
  }
}