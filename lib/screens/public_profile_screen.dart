import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'chat_room_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _supabaseService = SupabaseService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _supabaseService.getProfileById(widget.userId);
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
        ),
      );
    }
    if (_profile == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: Text(
            'Kullanıcı bulunamadı',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final fullName = "${_profile!['first_name']} ${_profile!['last_name']}";
    final username = "@${_profile!['username']}";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          username,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF1A1A1A),
            child: Icon(Icons.person, size: 40, color: Colors.white38),
          ),
          const SizedBox(height: 12),
          Text(
            fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- MESAJ GÖNDER BUTONU (HATA DÜZELTİLDİ) ---
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.message, size: 18),
                label: const Text('Mesaj Gönder'),
                onPressed: () async {
                  // Sadece widget.userId gönderiliyor, null veya isim yok!
                  final chatId = await _supabaseService.getOrCreateChat(
                    widget.userId,
                  );
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                          chatId: chatId,
                          otherUserId: widget.userId,
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 12),
              // --- TAKİP ET BUTONU ---
              FutureBuilder<List<String>>(
                future: _supabaseService.getMyFollowingIds(),
                builder: (context, snapshot) {
                  final isFollowing = (snapshot.data ?? []).contains(
                    widget.userId,
                  );
                  return OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isFollowing
                          ? Colors.white38
                          : Colors.tealAccent,
                      side: BorderSide(
                        color: isFollowing ? Colors.white10 : Colors.tealAccent,
                      ),
                    ),
                    icon: Icon(
                      isFollowing ? Icons.check : Icons.person_add,
                      size: 18,
                    ),
                    label: Text(isFollowing ? 'Takiptesin' : 'Takip Et'),
                    onPressed: () async {
                      await _supabaseService.toggleFollow(widget.userId);
                      setState(() {});
                    },
                  );
                },
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 40),
          const Text(
            'AÇIK PAYLAŞIMLAR',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabaseService.getUserPublicPostsStream(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepPurpleAccent,
                    ),
                  );
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return const Center(
                    child: Text(
                      'Henüz açık paylaşım yok.',
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return Card(
                      color: const Color(0xFF121212),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.white10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          post['content'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
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
