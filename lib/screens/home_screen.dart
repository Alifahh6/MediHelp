// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:medi_help/services/session_service.dart';
import 'package:medi_help/routes.dart';
import 'package:medi_help/screens/activity_screen.dart';
import 'package:medi_help/screens/faq_screen.dart';
import 'package:medi_help/screens/profile_screen.dart';
import 'package:medi_help/providers/location_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _controller;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  final List<Map<String, dynamic>> _features = [
    {'title': 'Antrian',     'icon': Icons.queue_play_next, 'route': AppRoutes.queue,    'color': const Color(0xFF1E88E5)},
    {'title': 'Terdekat',    'icon': Icons.location_on,     'route': AppRoutes.nearby,   'color': const Color(0xFF1565C0)},
    {'title': 'Rekam Medis', 'icon': Icons.folder,          'route': AppRoutes.records,  'color': const Color(0xFF1E88E5)},
    {'title': 'Riwayat',     'icon': Icons.history,         'route': AppRoutes.history,  'color': const Color(0xFF1565C0)},
    {'title': 'Pengingat',   'icon': Icons.notifications,   'route': AppRoutes.reminder, 'color': const Color(0xFF1E88E5)},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SessionService>(context, listen: false).loadSession();
      context.read<LocationProvider>().init();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    await Provider.of<SessionService>(context, listen: false).loadSession();
    await context.read<LocationProvider>().refresh();
  }

  String _formatCount(int count) {
    if (count == 0) return '0';
    if (count >= 1000) { final k = count / 1000; return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}k+'; }
    return '$count+';
  }

  String _formatAge(int days) {
    if (days >= 365) return '${(days / 365).floor()} Tahun+';
    if (days >= 30)  return '${(days / 30).floor()} Bulan+';
    return '$days Hari+';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [_buildHomeContent(), const ActivityScreen(), const FaqScreen(), const ProfileScreen()];
    final appBars = [
      _buildHomeAppBar(isDark),
      _buildSimpleAppBar('My Activity'),
      _buildSimpleAppBar('FAQ'),
      _buildSimpleAppBar('My Profile'),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: appBars[_currentIndex],
      // IndexedStack: state semua tab dipertahankan (foto profil tidak hilang saat pindah tab)
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  PreferredSizeWidget _buildHomeAppBar(bool isDark) {
    return AppBar(
      toolbarHeight: 56,
      title: Row(children: [
        Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Image.asset('assets/images/Logo.png', width: 24, height: 24,
                errorBuilder: (_, __, ___) => const Icon(Icons.local_hospital, color: Color(0xFF1E88E5), size: 24))),
        const SizedBox(width: 12),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('MediHelp', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          Text('Health Care', style: TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w400)),
        ]),
      ]),
      elevation: 0, backgroundColor: const Color(0xFF1E88E5),
      actions: [Consumer<SessionService>(builder: (context, session, _) {
        if (!session.isLoggedIn) {
          return Padding(padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: const Text('Masuk', style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.w600, fontSize: 13)))));
        }
        return const SizedBox.shrink();
      })],
    );
  }

  // AppBar tanpa logo (Activity, FAQ, Profile)
  PreferredSizeWidget _buildSimpleAppBar(String title) {
    return AppBar(
      toolbarHeight: 56,
      title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      elevation: 0, backgroundColor: const Color(0xFF1E88E5),
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -2))]),
      child: BottomNavigationBar(
        currentIndex: _currentIndex, onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed, backgroundColor: Colors.transparent, elevation: 0,
        selectedItemColor: const Color(0xFF1E88E5),
        unselectedItemColor: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
        selectedFontSize: 12, unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined),        activeIcon: Icon(Icons.home),         label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline),          activeIcon: Icon(Icons.help),         label: 'FAQ'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline),        activeIcon: Icon(Icons.person),       label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Consumer2<SessionService, LocationProvider>(builder: (context, session, loc, _) {
      final isDark    = Theme.of(context).brightness == Brightness.dark;
      final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
      final subColor  = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
      final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

      return RefreshIndicator(
        key: _refreshKey, color: const Color(0xFF1E88E5), onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Layanan Cepat ────────────────────────────────────
            // (Search bar dihapus sesuai permintaan)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Layanan Cepat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3, childAspectRatio: 0.9, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: _features.length,
                  itemBuilder: (context, index) {
                    final f = _features[index];
                    return _buildServiceCard(f, !session.isLoggedIn, isDark, textColor);
                  },
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // ── Banner ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF1565C0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Jaga kesehatan\nkeluargamu sejak dini',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () { HapticFeedback.lightImpact(); Navigator.pushNamed(context, AppRoutes.faq); },
                      child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: const Text('Pelajari lebih', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E88E5)))),
                    ),
                  ])),
                  const Icon(Icons.family_restroom, color: Colors.white, size: 56),
                ]),
              ),
            ),

            const SizedBox(height: 24),

            // ── Stats ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                    child: Column(children: [
                      Text(_formatCount(session.totalUsers), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E88E5))),
                      const SizedBox(height: 4),
                      Text('Pengguna', style: TextStyle(fontSize: 13, color: subColor, fontWeight: FontWeight.w500)),
                    ]))),
                const SizedBox(width: 12),
                Expanded(child: Container(padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                    child: Column(children: [
                      Text(_formatAge(session.appAgeDays), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E88E5))),
                      const SizedBox(height: 4),
                      Text('Aktif Beroperasi', style: TextStyle(fontSize: 13, color: subColor, fontWeight: FontWeight.w500)),
                    ]))),
              ]),
            ),

            const SizedBox(height: 24),

            // ── Fasilitas Terdekat Header ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  const Icon(Icons.location_on, color: Color(0xFF1E88E5), size: 20), const SizedBox(width: 6),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Fasilitas Terdekat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                    Text(loc.locationLabel, style: TextStyle(fontSize: 12, color: subColor)),
                  ]),
                ]),
                GestureDetector(
                  onTap: () => loc.refresh(),
                  child: Container(padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF1E88E5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.refresh, color: Color(0xFF1E88E5), size: 18)),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Facility List (top 3, semua tipe) ─────────────
            loc.isLoading
                ? const Padding(padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Column(children: [
                      CircularProgressIndicator(color: Color(0xFF1E88E5)), SizedBox(height: 12),
                      Text('Mencari fasilitas terdekat...', style: TextStyle(color: Color(0xFF1E88E5), fontSize: 13)),
                    ])))
                : Column(children: loc.facilities.take(3).map((f) =>
                    _buildFacilityCard(f, isDark, textColor, subColor, cardColor)).toList()),

            const SizedBox(height: 24),

            // ── Book Now CTA ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dapatkan Antrianmu dengan Mudah', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Kami paham waktumu berharga. MediHelp memungkinkanmu mengambil antrian secara online.',
                          style: TextStyle(fontSize: 13, color: subColor, height: 1.6)),
                      const SizedBox(height: 20),
                      Row(children: [
                        Container(padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.location_on_outlined, color: Color(0xFF1E88E5), size: 18)),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Lokasi', style: TextStyle(fontSize: 12, color: subColor)),
                          Text('Lokasi kamu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                        ]),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Provider.of<SessionService>(context, listen: false).checkLogin(context, () => Navigator.pushNamed(context, AppRoutes.queue));
                          },
                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF1565C0)]),
                                  borderRadius: BorderRadius.circular(25)),
                              child: const Text('Book Now', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
                        ),
                      ]),
                    ])),
              ]),
            ),

            const SizedBox(height: 24),
          ]),
        ),
      );
    });
  }

  Widget _buildServiceCard(Map<String, dynamic> feature, bool isLocked, bool isDark, Color textColor) {
    final color = feature['color'] as Color;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final session = Provider.of<SessionService>(context, listen: false);
        if (isLocked) Navigator.pushNamed(context, AppRoutes.login);
        else session.checkLogin(context, () => Navigator.pushNamed(context, feature['route'] as String));
      },
      child: Container(
        decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white, borderRadius: BorderRadius.circular(16),
            border: isDark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(isDark ? 0.2 : 0.1), shape: BoxShape.circle),
              child: Icon(feature['icon'] as IconData, color: color, size: 24)),
          const SizedBox(height: 8),
          Text(feature['title'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor), textAlign: TextAlign.center),
          if (isLocked) ...[const SizedBox(height: 2), const Text('Login', style: TextStyle(fontSize: 10, color: Colors.grey))],
        ]),
      ),
    );
  }

  Widget _buildFacilityCard(NearbyFacility f, bool isDark, Color textColor, Color subColor, Color cardColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(18),
          border: isDark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(children: [
        Container(width: 52, height: 52,
            decoration: BoxDecoration(color: isDark ? f.iconColor.withOpacity(0.2) : f.bgColor, borderRadius: BorderRadius.circular(14)),
            child: Icon(f.icon, color: f.iconColor, size: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            Text(f.category, style: TextStyle(fontSize: 12, color: subColor)),
            Container(margin: const EdgeInsets.symmetric(horizontal: 6), width: 3, height: 3, decoration: BoxDecoration(color: subColor, shape: BoxShape.circle)),
            Icon(Icons.location_on, size: 12, color: subColor), const SizedBox(width: 2),
            Text(f.distance, style: TextStyle(fontSize: 12, color: subColor)),
          ]),
          Text(f.address, style: TextStyle(fontSize: 11, color: subColor), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); Navigator.pushNamed(context, AppRoutes.nearby); },
          child: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.directions_outlined, color: Color(0xFF1E88E5), size: 18)),
        ),
      ]),
    );
  }
}