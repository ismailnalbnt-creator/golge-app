import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'public_profile_screen.dart';

class RadarScreen extends StatefulWidget {
  const RadarScreen({super.key});

  @override
  State<RadarScreen> createState() => _RadarScreenState();
}

class _RadarScreenState extends State<RadarScreen> {
  final _supabaseService = SupabaseService();

  bool _isLocationVisible = false;
  double _searchRadius = 20.0;
  bool _isLoading = false;

  double _myLat = 39.9334;
  double _myLng = 32.8597;

  @override
  void initState() {
    super.initState();
    _loadCurrentVisibility();
  }

  Future<void> _loadCurrentVisibility() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _supabaseService.getCurrentUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _isLocationVisible = profile['is_location_visible'] ?? false;
          if (profile['lat'] != null) _myLat = profile['lat'];
          if (profile['lng'] != null) _myLng = profile['lng'];
        });
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleVisibility(bool value) async {
    setState(() => _isLoading = true);
    try {
      await _supabaseService.updateLocationVisibility(
        value,
        lat: _myLat,
        lng: _myLng,
      );
      setState(() {
        _isLocationVisible = value;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Radarda Görün',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isLocationVisible
                              ? 'Çevrendeki gölgeler seni görebilir.'
                              : 'Konumun tamamen gizli.',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.deepPurpleAccent,
                            ),
                          )
                        : Switch(
                            value: _isLocationVisible,
                            activeThumbColor: Colors.deepPurpleAccent,
                            onChanged: _toggleVisibility,
                          ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Arama Çapı',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_searchRadius.round()} KM',
                      style: const TextStyle(
                        color: Colors.deepPurpleAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _searchRadius,
                  min: 5,
                  max: 100,
                  divisions: 19,
                  activeColor: Colors.deepPurpleAccent,
                  inactiveColor: Colors.white10,
                  onChanged: (value) {
                    setState(() {
                      _searchRadius = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabaseService.getVisibleUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepPurpleAccent,
                    ),
                  );
                }

                final allVisibleUsers = snapshot.data ?? [];

                final nearbyUsers = allVisibleUsers.where((userProfile) {
                  if (currentUser != null &&
                      userProfile['id'] == currentUser.id) {
                    return false;
                  }
                  if (userProfile['lat'] == null ||
                      userProfile['lng'] == null) {
                    return false;
                  }

                  final distance = _calculateDistance(
                    _myLat,
                    _myLng,
                    userProfile['lat'],
                    userProfile['lng'],
                  );

                  userProfile['computed_distance'] = distance;
                  return distance <= _searchRadius;
                }).toList();

                nearbyUsers.sort(
                  (a, b) => (a['computed_distance'] as double).compareTo(
                    b['computed_distance'] as double,
                  ),
                );

                if (nearbyUsers.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.radar, size: 48, color: Colors.white24),
                          SizedBox(height: 16),
                          Text(
                            'Bu çapta aktif gölge bulunamadı.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: nearbyUsers.length,
                  itemBuilder: (context, index) {
                    final targetUser = nearbyUsers[index];
                    final fullName =
                        "${targetUser['first_name']} ${targetUser['last_name']}";
                    final username = "@${targetUser['username']}";
                    final distance = targetUser['computed_distance'] as double;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 22,
                            backgroundColor: Color(0xFF1E1E1E),
                            child: Icon(
                              Icons.person,
                              color: Colors.deepPurpleAccent,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  username,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                distance < 1
                                    ? 'Çok Yakında'
                                    : '${distance.toStringAsFixed(1)} KM',
                                style: const TextStyle(
                                  color: Colors.deepPurpleAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(
                                    0,
                                    32,
                                  ), // dense hatasını çözmek için minimumSize kullandık
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PublicProfileScreen(
                                        userId: targetUser['id'],
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Görüntüle',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
