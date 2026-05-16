// lib/screens/records_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadRecordsFromFirestore();
  }

  Future<void> _loadRecordsFromFirestore() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('records')
          .orderBy('uploadedAt', descending: true)
          .get();

      setState(() {
        _records = snapshot.docs.map((doc) {
          final data = doc.data();
          final fileName =
              data['displayName'] as String? ?? data['fileName'] as String? ?? 'unknown';
          final originalFileName = data['fileName'] as String? ?? 'unknown';
          final ext = originalFileName.contains('.')
              ? originalFileName.split('.').last.toLowerCase()
              : 'file';
          DateTime uploadedAt;
          try {
            final ts = data['uploadedAt'];
            uploadedAt = ts is Timestamp ? ts.toDate() : DateTime.now();
          } catch (_) {
            uploadedAt = DateTime.now();
          }
          return {
            'id': doc.id,
            'title': fileName,
            'originalFileName': originalFileName,
            'path': data['localPath'] ?? '',
            'size': _formatSize(data['fileSize'] as int? ?? 0),
            'date': DateFormat('d MMMM yyyy', 'id_ID').format(uploadedAt),
            'ext': ext,
            'isImage': ['jpg', 'jpeg', 'png', 'heic'].contains(ext),
          };
        }).toList();
        _isLoading = false;
      });
      debugPrint('✅ Loaded ${_records.length} records from Firestore');
    } catch (e) {
      debugPrint('❌ Error loading records: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _saveRecordToFirestore({
    required String fileName,
    required String localPath,
    required int fileSize,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'file';

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('records')
          .add({
        'fileName': fileName,
        'displayName': fileName, // nama yang bisa diedit
        'localPath': localPath,
        'fileSize': fileSize,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activities')
          .add({
        'type': 'record',
        'title': 'Upload dokumen: $fileName',
        'description': 'Ukuran: ${_formatSize(fileSize)}',
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _records.insert(0, {
          'id': docRef.id,
          'title': fileName,
          'originalFileName': fileName,
          'path': localPath,
          'size': _formatSize(fileSize),
          'date': DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now()),
          'ext': ext,
          'isImage': ['jpg', 'jpeg', 'png', 'heic'].contains(ext),
        });
      });

      debugPrint('✅ Record saved to Firestore: $fileName');
    } catch (e) {
      debugPrint('❌ Error saving record: $e');
    }
  }

  // ─── EDIT nama file ───────────────────────────────────────
  void _showEditDialog(int index) {
    final record = _records[index];
    final currentName = record['title'] as String;
    // Pisahkan nama dari ekstensi
    final ext = record['ext'] as String;
    final nameWithoutExt = currentName.contains('.')
        ? currentName.substring(0, currentName.lastIndexOf('.'))
        : currentName;

    final controller = TextEditingController(text: nameWithoutExt);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Ubah Nama File',
          style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E1E1E)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E1E1E)),
              decoration: InputDecoration(
                hintText: 'Nama file baru',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF1E88E5), width: 1.5),
                ),
                suffixText: '.$ext',
                suffixStyle: TextStyle(color: Colors.grey.shade500),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ekstensi .$ext akan dipertahankan',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              final fullName = '$newName.$ext';
              Navigator.pop(context);
              await _updateFileName(index, fullName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateFileName(int index, String newName) async {
    final record = _records[index];
    final docId = record['id'] as String?;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null && docId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('records')
            .doc(docId)
            .update({'displayName': newName});

        setState(() {
          _records[index] = {...record, 'title': newName};
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nama file berhasil diubah!'),
              backgroundColor: Color(0xFF1E88E5),
            ),
          );
        }
        debugPrint('✅ File renamed to: $newName');
      } catch (e) {
        debugPrint('❌ Rename error: $e');
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'doc', 'docx', 'xls', 'xlsx',
        'jpg', 'jpeg', 'png', 'heic', 'txt'
      ],
    );

    if (result != null) {
      for (final file in result.files) {
        if (file.path != null) {
          final f = File(file.path!);
          final size = await f.length();
          await _saveRecordToFirestore(
            fileName: file.name,
            localPath: file.path!,
            fileSize: size,
          );
        }
      }
    }
  }

  Future<void> _pickFromCamera() async {
    final XFile? photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo != null) {
      final file = File(photo.path);
      final size = await file.length();
      final name = 'Photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _saveRecordToFirestore(
        fileName: name,
        localPath: photo.path,
        fileSize: size,
      );
    }
  }

  void _showPickOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('Tambah Dokumen',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E1E1E))),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder_open,
                    color: Color(0xFF1E88E5), size: 24),
              ),
              title: Text('Pilih dari Penyimpanan',
                  style: TextStyle(
                      color:
                          isDark ? Colors.white : const Color(0xFF1E1E1E))),
              subtitle: const Text('PDF, Word, Excel, Gambar'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFF1E88E5), size: 24),
              ),
              title: Text('Ambil Foto dengan Kamera',
                  style: TextStyle(
                      color:
                          isDark ? Colors.white : const Color(0xFF1E1E1E))),
              subtitle: const Text('Foto dokumen langsung'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int index) {
    final record = _records[index];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Dokumen'),
        content: Text('Hapus "${record['title']}" dari daftar records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final userId = FirebaseAuth.instance.currentUser?.uid;
              final docId = record['id'] as String?;
              if (userId != null && docId != null) {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('records')
                      .doc(docId)
                      .delete();
                  debugPrint('✅ Record deleted from Firestore');
                } catch (e) {
                  debugPrint('❌ Delete error: $e');
                }
              }
              setState(() => _records.removeAt(index));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, elevation: 0),
            child: const Text('Hapus',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String ext) {
    switch (ext) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': case 'docx': return Icons.description;
      case 'xls': case 'xlsx': return Icons.table_chart;
      case 'jpg': case 'jpeg': case 'png': case 'heic': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String ext) {
    switch (ext) {
      case 'pdf': return Colors.red.shade600;
      case 'doc': case 'docx': return Colors.blue.shade600;
      case 'xls': case 'xlsx': return Colors.green.shade600;
      case 'jpg': case 'jpeg': case 'png': case 'heic': return Colors.purple.shade500;
      default: return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        toolbarHeight: 56,
        title: const Text('Records',
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
              _loadRecordsFromFirestore();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E88E5)))
          : _records.isEmpty
              ? _buildEmptyState(isDark, subColor)
              : _buildRecordList(isDark, textColor, subColor),
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
          onPressed: _showPickOptions,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color subColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E88E5).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder_open,
                size: 64, color: Color(0xFF1E88E5)),
          ),
          const SizedBox(height: 20),
          Text('Belum ada dokumen',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E1E1E))),
          const SizedBox(height: 8),
          Text('Ketuk + untuk menambahkan dokumen medis',
              style: TextStyle(fontSize: 14, color: subColor)),
        ],
      ),
    );
  }

  Widget _buildRecordList(bool isDark, Color textColor, Color subColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        final ext = record['ext'] as String;
        final isImage = record['isImage'] as bool;
        final path = record['path'] as String?;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isImage && path != null && path.isNotEmpty
                  ? Image.file(File(path),
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fileIconBox(ext))
                  : _fileIconBox(ext),
            ),
            title: Text(
              record['title'],
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Diunggah: ${record['date']}',
                    style: TextStyle(fontSize: 11, color: subColor)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getFileColor(ext).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(ext.toUpperCase(),
                          style: TextStyle(
                              fontSize: 10,
                              color: _getFileColor(ext),
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text(record['size'],
                        style: TextStyle(fontSize: 11, color: subColor)),
                  ],
                ),
              ],
            ),
            // Trailing: Edit + Delete
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      color: Color(0xFF1E88E5), size: 20),
                  onPressed: () => _showEditDialog(index),
                  tooltip: 'Ubah nama',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red.shade300, size: 22),
                  onPressed: () => _confirmDelete(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Membuka: ${record['title']}'),
                  backgroundColor: const Color(0xFF1E88E5),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _fileIconBox(String ext) {
    return Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: _getFileColor(ext).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_getFileIcon(ext), color: _getFileColor(ext), size: 28),
    );
  }
}