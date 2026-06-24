import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final supabaseService = SupabaseService();

    return Column(
      children: [
        // --- 1. KISIM: GERÇEK KİMLİK BİLGİLERİ PANELİ ---
        FutureBuilder<Map<String, dynamic>?>(
          future: supabaseService.getCurrentUserProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 180,
                color: Colors.black,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.deepPurpleAccent,
                  ),
                ),
              );
            }

            final profile = snapshot.data;
            final fullName = profile != null
                ? "${profile['first_name']} ${profile['last_name']}"
                : "Bilinmeyen Gölge";
            final username = profile != null ? "@${profile['username']}" : "";
            final birthDateStr =
                profile != null && profile['birth_date'] != null
                ? "${DateTime.parse(profile['birth_date']).day}/${DateTime.parse(profile['birth_date']).month}/${DateTime.parse(profile['birth_date']).year}"
                : "-";

            return Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(bottom: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 36,
                        backgroundColor: Color(0xFF1E1E1E),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white54,
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              username,
                              style: const TextStyle(
                                color: Colors.deepPurpleAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Hiyerarşik detaylar
                            Row(
                              children: [
                                const Icon(
                                  Icons.cake,
                                  size: 14,
                                  color: Colors.white38,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  birthDateStr,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.email,
                                  size: 14,
                                  color: Colors.white38,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    user?.email ?? '',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.logout, size: 16),
                    label: const Text('Maskeyi Çıkar (Çıkış Yap)'),
                    onPressed: () async {
                      await supabaseService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const AuthScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),

        // --- 2. KISIM: ARŞİV BAŞLIĞI ---
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: const Color(0xFF121212),
          child: const Text(
            'Senin Fısıltıların',
            style: TextStyle(
              color: Colors.deepPurpleAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 12,
            ),
          ),
        ),

        // --- 3. KISIM: KİŞİSEL ARŞİVİN LİSTELENMESİ ---
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabaseService.getMyPostsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.deepPurpleAccent,
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Hata: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final posts = snapshot.data;
              if (posts == null || posts.isEmpty) {
                return const Center(
                  child: Text(
                    'Henüz hiçbir şey fısıldamadın.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final bool isPostAnonymous = post['is_anonymous'] ?? false;

                  return Card(
                    color: const Color(0xFF1A1A1A),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      // ignore: deprecated_member_use
                      side: BorderSide(
                        color: isPostAnonymous
                            // ignore: deprecated_member_use
                            ? Colors.deepPurpleAccent.withOpacity(0.3)
                            : Colors.white12,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isPostAnonymous
                                        ? Icons.masks
                                        : Icons.account_circle,
                                    color: isPostAnonymous
                                        ? Colors.deepPurpleAccent
                                        : Colors.white54,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isPostAnonymous
                                        ? 'Gölge Paylaşımı'
                                        : 'Açık Paylaşım',
                                    style: TextStyle(
                                      color: isPostAnonymous
                                          ? Colors.deepPurpleAccent
                                          : Colors.white54,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.only(right: 40.0),
                                child: Text(
                                  post['content'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _VoteStats(postId: post['id']),
                            ],
                          ),
                        ),

                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(
                              Icons.local_fire_department,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E1E1E),
                                  title: const Text(
                                    'Dosyayı Yak?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    'Süreci durdurup bu delili imha etmek istediğine emin misin?',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text(
                                        'Vazgeç',
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'İmha Et',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  await supabaseService.deletePost(post['id']);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Hata: $e')),
                                    );
                                  }
                                }
                              }
                            },
                          ),
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
    );
  }
}

class _VoteStats extends StatelessWidget {
  final String postId;
  const _VoteStats({required this.postId});

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabaseService.getVotesStream(postId),
      builder: (context, snapshot) {
        int lightVotes = 0;
        int shadowVotes = 0;

        if (snapshot.hasData) {
          final votes = snapshot.data!;
          for (var vote in votes) {
            if (vote['vote_type'] == 1) lightVotes++;
            if (vote['vote_type'] == -1) shadowVotes++;
          }
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Icon(Icons.arrow_upward, color: Colors.amber, size: 14),
            const SizedBox(width: 4),
            Text(
              '$lightVotes',
              style: const TextStyle(color: Colors.amber, fontSize: 12),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.arrow_downward,
              color: Colors.deepPurpleAccent,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '$shadowVotes',
              style: const TextStyle(
                color: Colors.deepPurpleAccent,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}
