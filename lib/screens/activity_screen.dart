// lib/screens/activity_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1E1E);
    final subColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        // Tidak ada AppBar — HomeScreen yang kelola
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.lock_outline, size: 64, color: Color(0xFF1E88E5)),
            ),
            const SizedBox(height: 20),
            Text('Silakan login terlebih dahulu',
                style: TextStyle(fontSize: 16, color: textColor)),
          ]),
        ),
      );
    }

    return Scaffold(
      // Tidak ada AppBar — HomeScreen yang kelola
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('activities')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final activities = snapshot.data?.docs ?? [];

          if (activities.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withOpacity(0.08), shape: BoxShape.circle),
                  child: const Icon(Icons.history_outlined, size: 64, color: Color(0xFF1E88E5)),
                ),
                const SizedBox(height: 20),
                Text('Belum ada aktivitas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor)),
                const SizedBox(height: 8),
                Text(
                  'Aktivitas muncul otomatis saat kamu\nmenggunakan Reminder, Queue, atau Nearby',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: subColor, height: 1.5),
                ),
              ]),
            );
          }

          // Group by date
          final Map<String, List<QueryDocumentSnapshot>> grouped = {};
          for (final activity in activities) {
            final data = activity.data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as Timestamp?;
            if (timestamp == null) continue;
            final date = timestamp.toDate();
            final key = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
            grouped.putIfAbsent(key, () => []).add(activity);
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, top: 8),
                    child: Row(children: [
                      Container(width: 4, height: 18,
                          decoration: BoxDecoration(color: const Color(0xFF1E88E5),
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 10),
                      Text(entry.key,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                              color: Color(0xFF1E88E5))),
                    ]),
                  ),
                  ...entry.value.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final timestamp = data['timestamp'] as Timestamp;
                    final type = data['type'] ?? 'activity';
                    final title = data['title'] ?? 'Aktivitas';
                    final description = data['description'] ?? '';
                    return _buildActivityCard(
                      type: type, title: title, description: description,
                      timestamp: timestamp.toDate(),
                      isDark: isDark, cardColor: cardColor, subColor: subColor, textColor: textColor,
                    );
                  }),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildActivityCard({
    required String type, required String title, required String description,
    required DateTime timestamp, required bool isDark,
    required Color cardColor, required Color subColor, required Color textColor,
  }) {
    final info = _getActivityInfo(type);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: info.color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: Icon(info.icon, color: info.color, size: 24),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: info.color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(info.label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: info.color)),
          ),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(description, style: TextStyle(fontSize: 13, color: subColor)),
          ],
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(children: [
            Icon(Icons.access_time, size: 14, color: subColor),
            const SizedBox(width: 4),
            Text(DateFormat('HH:mm').format(timestamp), style: TextStyle(fontSize: 12, color: subColor)),
          ]),
        ),
      ),
    );
  }

  ({IconData icon, Color color, String label}) _getActivityInfo(String type) {
    switch (type) {
      case 'reminder':
        return (icon: Icons.alarm, color: const Color(0xFFFF9800), label: 'Reminder');
      case 'queue':
        return (icon: Icons.queue, color: const Color(0xFF9C27B0), label: 'Queue');
      case 'visit':
        return (icon: Icons.local_hospital, color: const Color(0xFF1E88E5), label: 'Kunjungan');
      case 'record':
        return (icon: Icons.upload_file, color: const Color(0xFF4CAF50), label: 'Dokumen');
      case 'location':
        return (icon: Icons.location_on, color: const Color(0xFF2196F3), label: 'Lokasi');
      default:
        return (icon: Icons.history, color: Colors.grey, label: 'Aktivitas');
    }
  }
}