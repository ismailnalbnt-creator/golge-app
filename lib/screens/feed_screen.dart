import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

// KIRMIZI HATA BURADAYDI: _HomeScreenState yazan yeri _FeedScreenState olarak düzelttik
class _FeedScreenState extends State<FeedScreen> {
  final _postController = TextEditingController();
  final _supabaseService = SupabaseService();
  bool _isPosting = false;

  Future<void> _submitPost() async {
    final text = _postController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isPosting = true;
    });

    try {
      await _supabaseService.createPost(text);
      _postController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }

    if (mounted) {
      setState(() {
        _isPosting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: Colors.black,
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _postController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Aklından geçenleri fısılda...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _isPosting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.deepPurpleAccent,
                      ),
                      onPressed: _submitPost,
                    ),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabaseService.getPostsStream(),
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
                    'Bir hata oluştu: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final posts = snapshot.data;

              if (posts == null || posts.isEmpty) {
                return const Center(
                  child: Text(
                    'Henüz kimse bir şey fısıldamadı.\nİlk gölge sen ol.',
                    textAlign: TextAlign.center,
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
                  return _PostCard(post: posts[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;

  // MAVİ UYARI BURADAYDI: super.key eklentisi yapılarak uyarı giderildi
  // ignore: unused_element_parameter
  const _PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final supabaseService = SupabaseService();

    return Card(
      color: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.white12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anonim Gölge',
              style: TextStyle(
                color: Colors.deepPurpleAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post['content'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabaseService.getVotesStream(post['id']),
              builder: (context, snapshot) {
                int lightVotes = 0;
                int shadowVotes = 0;
                int myVote = 0;

                if (snapshot.hasData) {
                  final votes = snapshot.data!;
                  for (var vote in votes) {
                    if (vote['vote_type'] == 1) lightVotes++;
                    if (vote['vote_type'] == -1) shadowVotes++;
                    if (vote['user_id'] == currentUserId) {
                      myVote = vote['vote_type'] as int;
                    }
                  }
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // IŞIK (Yukarı Ok)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_upward,
                        color: myVote == 1 ? Colors.amber : Colors.grey,
                        size: 22,
                      ),
                      onPressed: () async {
                        try {
                          await supabaseService.castVote(post['id'], 1);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                          }
                        }
                      },
                    ),
                    Text(
                      '$lightVotes',
                      style: TextStyle(
                        color: myVote == 1 ? Colors.amber : Colors.grey,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // GÖLGE (Aşağı Ok)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_downward,
                        color: myVote == -1
                            ? Colors.deepPurpleAccent
                            : Colors.grey,
                        size: 22,
                      ),
                      onPressed: () async {
                        try {
                          await supabaseService.castVote(post['id'], -1);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                          }
                        }
                      },
                    ),
                    Text(
                      '$shadowVotes',
                      style: TextStyle(
                        color: myVote == -1
                            ? Colors.deepPurpleAccent
                            : Colors.grey,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
