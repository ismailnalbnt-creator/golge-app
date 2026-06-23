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
        // --- 1. KISIM: PROFİL BİLGİLERİ VE ÇIKIŞ BUTONU ---
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: const BoxDecoration(
            color: Colors.black,
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            children: [
              const Icon(Icons.account_circle, size: 80, color: Colors.white54),
              const SizedBox(height: 12),
              Text(
                user?.email ?? 'Bilinmeyen Gölge',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Maskeyi Çıkar (Çıkış)'),
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
        ),

        // --- 2. KISIM: KENDİ FISILTILARIM (ARŞİV BAŞLIĞI) ---
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
            ),
          ),
        ),

        // --- 3. KISIM: KENDİ GÖNDERİLERİMİ LİSTELEME ---
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
                    'Henüz karanlığa hiçbir şey fısıldamadın.',
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
                  return Card(
                    color: const Color(0xFF1A1A1A),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.white12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Silme butonu ile çakışmasın diye sağdan biraz boşluk bırakıyoruz
                              Padding(
                                padding: const EdgeInsets.only(right: 40.0),
                                child: Text(
                                  post['content'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _VoteStats(postId: post['id']),
                            ],
                          ),
                        ),

                        // SİLME (DOSYAYI YAK) BUTONU - Sağ Üst Köşe
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(
                              Icons.local_fire_department,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            tooltip: 'Delili Yok Et',
                            onPressed: () async {
                              // Silmeden önce ufak bir emin misin sorusu
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E1E1E),
                                  title: const Text(
                                    'Dosyayı Yak?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    'Bu sırrı sonsuza dek karanlığa gömmek istediğine emin misin?',
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

                              // Eğer kullanıcı 'İmha Et' dediyse sil
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
            const Icon(Icons.arrow_upward, color: Colors.amber, size: 16),
            const SizedBox(width: 4),
            Text('$lightVotes', style: const TextStyle(color: Colors.amber)),
            const SizedBox(width: 16),
            const Icon(
              Icons.arrow_downward,
              color: Colors.deepPurpleAccent,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              '$shadowVotes',
              style: const TextStyle(color: Colors.deepPurpleAccent),
            ),
          ],
        );
      },
    );
  }
}
