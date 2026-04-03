// lib/screens/activity_screen.dart
import 'package:flutter/material.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  final List<Map<String, dynamic>> _activities = const [
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
    {
      'title': 'Nearby Hospitals',
      'action': 'Searched location',
      'date': 'Friday, 02 March 2026',
      'time': '09:45',
      'icon': Icons.location_on,
      'color': Colors.red,
    },
    {
      'title': 'Queue Number A-25',
      'action': 'Queue taken',
      'date': 'Thursday, 01 March 2026',
      'time': '07:30',
      'icon': Icons.queue,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Activity'),
        backgroundColor: const Color(0xFF1F5E7A),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          final activity = _activities[index];
          return Card(
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
              trailing: const Icon(Icons.more_vert),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Detail: ${activity['title']}'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}