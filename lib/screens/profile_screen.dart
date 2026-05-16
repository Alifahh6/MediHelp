// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:medi_help/services/session_service.dart';
import 'package:medi_help/providers/app_settings_provider.dart';
import 'package:medi_help/providers/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:medi_help/routes.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

// Key SharedPreferences untuk menyimpan path foto profil
const _kProfileImagePath = 'profile_image_path';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _nameController    = TextEditingController();
  final _emailController   = TextEditingController();
  final _phoneController   = TextEditingController();
  String _selectedGender   = 'Perempuan';
  File?  _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfileImage(); // ← Muat foto dari SharedPreferences saat init
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final session = Provider.of<SessionService>(context, listen: false);
    _nameController.text  = session.userName ?? '';
    _emailController.text = session.userEmail ?? '';
  }

  // Muat path foto dari SharedPreferences
  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path  = prefs.getString(_kProfileImagePath);
      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          if (mounted) setState(() => _profileImage = file);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Profile image load error: $e');
    }
  }

  // Simpan path foto ke SharedPreferences
  Future<void> _saveProfileImage(File file) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kProfileImagePath, file.path);
    } catch (e) {
      debugPrint('⚠️ Profile image save error: $e');
    }
  }

  Future<void> _openUserLocationOnMaps() async {
    final loc = context.read<LocationProvider>();
    if (!loc.hasLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi belum terdeteksi, coba perbarui dulu')));
      return;
    }
    final uri = Uri.parse('https://www.google.com/maps?q=${loc.lat},${loc.lng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka Google Maps')));
    }
  }

  Future<void> _pickImage() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text('Pilih Foto Profil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E1E1E))),
        const SizedBox(height: 16),
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF1E88E5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF1E88E5))),
          title: Text('Ambil Foto dari Kamera', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1E1E))),
          onTap: () async {
            Navigator.pop(context);
            final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
            if (picked != null && mounted) {
              final file = File(picked.path);
              setState(() => _profileImage = file);
              await _saveProfileImage(file); // ← Simpan ke SharedPreferences
            }
          },
        ),
        ListTile(
          leading: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF1E88E5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.photo_library_outlined, color: Color(0xFF1E88E5))),
          title: Text('Pilih dari Galeri', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1E1E))),
          onTap: () async {
            Navigator.pop(context);
            final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
            if (picked != null && mounted) {
              final file = File(picked.path);
              setState(() => _profileImage = file);
              await _saveProfileImage(file); // ← Simpan ke SharedPreferences
            }
          },
        ),
        const SizedBox(height: 16),
      ])),
    );
  }

  void _openEditProfile() {
    final session = Provider.of<SessionService>(context, listen: false);
    _nameController.text  = session.userName ?? '';
    _emailController.text = session.userEmail ?? '';

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final isDark    = Theme.of(ctx).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
        final inputFill = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: isDark ? Colors.grey.shade600 : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 24),

              _label('Name', textColor), const SizedBox(height: 8),
              TextFormField(controller: _nameController, style: TextStyle(color: textColor),
                  decoration: _deco(hint: 'Nama lengkap', isDark: isDark, fill: inputFill),
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 16),

              _label('Email', textColor), const SizedBox(height: 8),
              TextFormField(controller: _emailController, style: TextStyle(color: textColor),
                  keyboardType: TextInputType.emailAddress, decoration: _deco(hint: 'Email', isDark: isDark, fill: inputFill)),
              const SizedBox(height: 16),

              _label('Nomor HP', textColor), const SizedBox(height: 8),
              TextFormField(controller: _phoneController, style: TextStyle(color: textColor),
                  keyboardType: TextInputType.phone, decoration: _deco(hint: 'Nomor telepon', isDark: isDark, fill: inputFill)),
              const SizedBox(height: 16),

              _label('Gender', textColor), const SizedBox(height: 8),
              StatefulBuilder(builder: (ctx2, setLocal) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: inputFill, borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonFormField<String>(
                  value: _selectedGender, dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                  style: TextStyle(color: textColor, fontSize: 14), decoration: const InputDecoration(border: InputBorder.none),
                  items: ['Laki-laki', 'Perempuan'].map((g) => DropdownMenuItem(value: g, child: Text(g, style: TextStyle(color: textColor)))).toList(),
                  onChanged: (v) { setLocal(() => _selectedGender = v!); setState(() => _selectedGender = v!); },
                ),
              )),
              const SizedBox(height: 32),

              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        side: BorderSide(color: isDark ? Colors.white38 : Colors.grey.shade300)),
                    child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diupdate'), backgroundColor: Color(0xFF1E88E5)));
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 0),
                  child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )),
              ]),
            ])),
          ),
        );
      },
    );
  }

  Widget _label(String text, Color c) => Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c));

  InputDecoration _deco({String hint = '', required bool isDark, required Color fill}) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400, fontSize: 14),
    filled: true, fillColor: fill,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  void _showLocationDialog() {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    showDialog(
      context: context,
      builder: (_) => Consumer<LocationProvider>(builder: (ctx, loc, __) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [const Icon(Icons.location_on, color: Color(0xFF1E88E5)), const SizedBox(width: 8), Text('Lokasi Saya', style: TextStyle(color: textColor))]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (loc.isLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)))
          else
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.my_location, size: 16, color: Color(0xFF1E88E5)), const SizedBox(width: 8),
                Expanded(child: Text(
                  loc.hasLocation ? 'Lat: ${loc.lat!.toStringAsFixed(6)}\nLng: ${loc.lng!.toStringAsFixed(6)}' : 'Gagal mendeteksi lokasi',
                  style: TextStyle(fontSize: 14, color: textColor))),
              ]),
              if (loc.hasLocation && !loc.isDefault) ...[
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green.shade600), const SizedBox(width: 6),
                      Text('Lokasi terdeteksi', style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                    ])),
              ],
              if (loc.isDefault) ...[
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700), const SizedBox(width: 6),
                      Text('Menggunakan lokasi default', style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontWeight: FontWeight.w500)),
                    ])),
              ],
            ]),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); context.read<LocationProvider>().refresh(); },
              child: const Text('Perbarui', style: TextStyle(color: Color(0xFF1E88E5)))),
          ElevatedButton(onPressed: () { Navigator.pop(context); _openUserLocationOnMaps(); },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5)),
              child: const Text('Lihat di Maps', style: TextStyle(color: Colors.white))),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final settings  = context.watch<AppSettingsProvider>();
    final loc       = context.watch<LocationProvider>();
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final subColor  = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final cardBg    = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Consumer<SessionService>(builder: (context, session, _) {
      if (!session.isLoggedIn) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
          body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: const Color(0xFF1E88E5).withOpacity(0.08), shape: BoxShape.circle),
                child: const Icon(Icons.lock_outline, size: 64, color: Color(0xFF1E88E5))),
            const SizedBox(height: 20),
            Text('Anda belum login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 8),
            Text('Login untuk mengakses profil', style: TextStyle(fontSize: 14, color: subColor)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E88E5),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                child: const Text('Login Sekarang', style: TextStyle(color: Colors.white))),
          ])),
        );
      }

      // Subtitle lokasi dari provider
      final String locationSub = loc.isLoading ? 'Mendeteksi...'
          : loc.hasLocation ? '📍 ${loc.lat!.toStringAsFixed(4)}°, ${loc.lng!.toStringAsFixed(4)}°'
          : '📍 Gagal mendeteksi lokasi';

      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        // Tidak ada AppBar — dikelola HomeScreen
        body: SingleChildScrollView(child: Column(children: [
          // ── Header gradient ──────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(gradient: LinearGradient(
                colors: [Color(0xFF1E88E5), Color(0xFF1565C0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            child: Column(children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _pickImage,
                child: Stack(children: [
                  Container(width: 100, height: 100,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3)),
                      child: ClipOval(child: _profileImage != null
                          ? Image.file(_profileImage!, fit: BoxFit.cover)
                          : const Icon(Icons.person, size: 54, color: Colors.white))),
                  Positioned(bottom: 0, right: 0, child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Color(0xFF1E88E5), size: 16))),
                ]),
              ),
              const SizedBox(height: 12),
              Text(session.userName ?? 'User', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(session.userEmail ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              const SizedBox(height: 24),
            ]),
          ),

          // ── Menu items ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              _card(isDark: isDark, bg: cardBg, onTap: _openEditProfile,
                  child: Row(children: [_icon(Icons.edit_outlined), const SizedBox(width: 14),
                    Expanded(child: Text('Edit Profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor))),
                    Icon(Icons.chevron_right, color: subColor, size: 20)])),
              const SizedBox(height: 12),

              _card(isDark: isDark, bg: cardBg, child: Row(children: [
                _icon(Icons.notifications_outlined), const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Notification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
                  Text(settings.notificationsEnabled ? 'Notifikasi aktif' : 'Notifikasi nonaktif', style: TextStyle(fontSize: 12, color: subColor)),
                ])),
                Switch(value: settings.notificationsEnabled, activeColor: const Color(0xFF1E88E5),
                    onChanged: (val) async {
                      await settings.toggleNotifications(val);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(val ? '🔔 Notifikasi diaktifkan' : '🔕 Notifikasi dinonaktifkan'),
                          backgroundColor: const Color(0xFF1E88E5)));
                    }),
              ])),
              const SizedBox(height: 12),

              _card(isDark: isDark, bg: cardBg, onTap: _showLocationDialog,
                  child: Row(children: [_icon(Icons.location_on_outlined), const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Location', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
                      Text(locationSub, style: TextStyle(fontSize: 12, color: subColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    Icon(Icons.chevron_right, color: subColor, size: 20)])),
              const SizedBox(height: 12),

              _card(isDark: isDark, bg: cardBg, child: Row(children: [
                _icon(Icons.dark_mode_outlined), const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dark Mode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
                  Text(settings.isDarkMode ? 'Mode gelap aktif' : 'Mode terang aktif', style: TextStyle(fontSize: 12, color: subColor)),
                ])),
                Switch(value: settings.isDarkMode, activeColor: const Color(0xFF1E88E5), onChanged: (val) => settings.toggleDarkMode(val)),
              ])),
              const SizedBox(height: 32),

              SizedBox(width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      // Hapus foto profil dari SharedPreferences saat logout
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove(_kProfileImagePath);
                      await session.logout();
                      if (mounted) {
                        setState(() => _profileImage = null);
                        messenger.showSnackBar(const SnackBar(content: Text('Anda telah logout'), backgroundColor: Color(0xFF1E88E5)));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 0),
                    child: const Text('Log out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  )),
            ]),
          ),
        ])),
      );
    });
  }

  Widget _icon(IconData icon) => Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFF1E88E5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: const Color(0xFF1E88E5), size: 22));

  Widget _card({required bool isDark, required Color bg, required Widget child, VoidCallback? onTap}) =>
      GestureDetector(onTap: onTap, child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
        child: child,
      ));
}