// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medi_help/widgets/feature_card.dart';
import 'package:medi_help/services/session_service.dart';
import 'package:medi_help/routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Map<String, dynamic>> _features = [
    {'title': 'Records', 'icon': Icons.folder, 'route': AppRoutes.records},
    {'title': 'Nearby', 'icon': Icons.location_on, 'route': AppRoutes.nearby},
    {'title': 'Take Queue', 'icon': Icons.queue, 'route': AppRoutes.queue},
    {'title': 'Reminder', 'icon': Icons.notifications_active, 'route': AppRoutes.reminder},
    {'title': 'History', 'icon': Icons.history, 'route': AppRoutes.history},
    {'title': 'Profile', 'icon': Icons.person, 'route': AppRoutes.profile},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SessionService>(context, listen: false).loadSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Consumer<SessionService>(
          builder: (context, session, _) {
            final userName = session.userName ?? 'User';
            return Text('Hello, $userName!');
          },
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1F5E7A),
        actions: [
          Consumer<SessionService>(
            builder: (context, session, _) {
              if (!session.isLoggedIn) {
                return TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.login);
                  },
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF1F5E7A),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.help_outline),
            label: 'FAQ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildActivityContent();
      case 2:
        return _buildFaqContent();
      case 3:
        return _buildProfileContent();
      default:
        return _buildHomeContent();
    }
  }

  // HOME CONTENT
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1F5E7A), Color(0xFF2E8B57)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Helping you manage your health\nanytime, anywhere.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.reminder);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1F5E7A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Get started'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Categories
          const Text(
            'Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F5E7A),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: _features.length,
            itemBuilder: (context, index) {
              final feature = _features[index];
              return FeatureCard(
                title: feature['title'],
                icon: feature['icon'],
                onTap: () {
                  _navigateToFeature(feature['route']);
                },
              );
            },
          ),
          const SizedBox(height: 24),
          
          // History Section
          const Text(
            'History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F5E7A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: Color(0xFF1F5E7A), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'My Activity',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saturday, 07 March 2026',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F5E7A),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.alarm, size: 20, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: const Text(
                              'Reminder set\nMethylprednisolone 4mg - 3x sehari setiap 8jam sekali',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ACTIVITY CONTENT
  Widget _buildActivityContent() {
    final List<Map<String, dynamic>> _activities = [
      {
        'title': 'Methylprednisolone 4mg',
        'action': 'Reminder set',
        'date': 'Saturday, 07 March 2026',
        'time': '08:00',
        'icon': Icons.alarm,
        'color': Colors.orange,
      },
      {
        'title': 'Medical Checkup',
        'action': 'Appointment scheduled',
        'date': 'Monday, 05 March 2026',
        'time': '10:30',
        'icon': Icons.calendar_today,
        'color': Colors.blue,
      },
      {
        'title': 'Lab Results',
        'action': 'Document uploaded',
        'date': 'Sunday, 04 March 2026',
        'time': '14:15',
        'icon': Icons.upload_file,
        'color': Colors.green,
      },
      {
        'title': 'Amoxicillin 500mg',
        'action': 'Reminder set',
        'date': 'Saturday, 03 March 2026',
        'time': '20:00',
        'icon': Icons.alarm,
        'color': Colors.orange,
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F5E7A),
          ),
        ),
        const SizedBox(height: 12),
        ..._activities.map((activity) => Card(
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
                color: activity['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                activity['icon'],
                color: activity['color'],
                size: 28,
              ),
            ),
            title: Text(
              activity['title'],
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
                  activity['action'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${activity['date']} • ${activity['time']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.activity);
            },
          ),
        )),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.activity);
            },
            child: const Text('View All Activity'),
          ),
        ),
      ],
    );
  }

  // FAQ CONTENT (Preview)
  Widget _buildFaqContent() {
    final List<Map<String, String>> _faqs = [
      {'q': 'Bagaimana cara menggunakan fitur antrian online?', 'a': 'Anda dapat menggunakan fitur Take Queue di halaman utama.'},
      {'q': 'Bagaimana cara menemukan fasilitas kesehatan terdekat?', 'a': 'Gunakan fitur Nearby untuk mencari faskes terdekat.'},
      {'q': 'Apakah MediHelp dapat menggantikan konsultasi dengan dokter?', 'a': 'Tidak. MediHelp hanya aplikasi pendukung.'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F5E7A),
          ),
        ),
        const SizedBox(height: 12),
        ..._faqs.map((faq) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: const Icon(Icons.help_outline, color: Color(0xFF1F5E7A)),
            title: Text(
              faq['q']!,
              style: const TextStyle(fontSize: 14),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  faq['a']!,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.faq);
            },
            child: const Text('View All FAQs'),
          ),
        ),
      ],
    );
  }

  // PROFILE CONTENT (Preview)
  Widget _buildProfileContent() {
    return Consumer<SessionService>(
      builder: (context, session, _) {
        if (!session.isLoggedIn) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Anda belum login'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F5E7A),
                  ),
                  child: const Text('Login Sekarang'),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF1F5E7A).withOpacity(0.1),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Color(0xFF1F5E7A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    session.userName ?? 'User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    session.userEmail ?? 'user@example.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline, color: Color(0xFF1F5E7A)),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.profile);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.history, color: Color(0xFF1F5E7A)),
                    title: const Text('History'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.history);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.red),
                    onTap: () async {
                      await session.logout();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Anda telah logout')),
                      );
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToFeature(String route) {
    final session = Provider.of<SessionService>(context, listen: false);
    
    if (route == AppRoutes.profile) {
      Navigator.pushNamed(context, route);
    } else {
      session.checkLogin(context, () {
        Navigator.pushNamed(context, route);
      });
    }
  }
}