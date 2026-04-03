// lib/screens/nearby_screen.dart
import 'package:flutter/material.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  String _selectedFilter = 'ALL';
  final List<String> _filters = ['ALL', 'Rumah Sakit', 'Puskesmas'];
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _hospitals = [
    {
      'name': 'Rumah Sakit Islam',
      'address': 'J Ahmad Yani No.2-4, Wonokromo, Kec. Wonokromo, Surabaya, Jawa Timur 60243',
      'distance': '800m',
      'type': 'Rumah Sakit',
      'waitTime': '30 menit',
      'rating': 4.5,
      'phone': '(031) 1234567',
    },
    {
      'name': 'Rumah Sakit Darmo',
      'address': 'Jl. Darmo No.86, Surabaya',
      'distance': '1.2km',
      'type': 'Rumah Sakit',
      'waitTime': '40 menit',
      'rating': 4.3,
      'phone': '(031) 7654321',
    },
    {
      'name': 'Puskesmas Wonokromo',
      'address': 'Jl. Wonokromo No.15, Surabaya',
      'distance': '500m',
      'type': 'Puskesmas',
      'waitTime': '20 menit',
      'rating': 4.0,
      'phone': '(031) 9876543',
    },
    {
      'name': 'Royal Hospital Surabaya',
      'address': 'Jl. Raya Gubeng No.45, Surabaya',
      'distance': '2.5km',
      'type': 'Rumah Sakit',
      'waitTime': '80 menit',
      'rating': 4.7,
      'phone': '(031) 5551234',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Nearby'),
        backgroundColor: const Color(0xFF1F5E7A),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
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
          
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _filters.map((filter) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    selectedColor: const Color(0xFF1F5E7A).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF1F5E7A),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Map placeholder
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.map,
                    size: 50,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Map View',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // List of hospitals
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _hospitals.length,
              itemBuilder: (context, index) {
                final hospital = _hospitals[index];
                if (_selectedFilter != 'ALL' && hospital['type'] != _selectedFilter) {
                  return const SizedBox();
                }
                return _buildHospitalCard(hospital, context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalCard(Map<String, dynamic> hospital, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
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
                        Icons.local_hospital,
                        color: Color(0xFF1F5E7A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hospital['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hospital['address'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          hospital['distance'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Waktu Menunggu: ${hospital['waitTime']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        _showDetailsDialog(hospital, context);
                      },
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> hospital, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(hospital['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hospital['address']),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text('Waktu Menunggu: ${hospital['waitTime']}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16),
                  const SizedBox(width: 4),
                  Text(hospital['phone']),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/queue');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F5E7A),
              ),
              child: const Text('Take Queue'),
            ),
          ],
        );
      },
    );
  }
}