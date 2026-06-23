import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class CourtScreen extends StatelessWidget {
  const CourtScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          color: Colors.black,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '⚖️ AKTİF DAVALAR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Gölgelerin vicdanı burada oylanıyor. Kararını ver.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: supabaseService.getPostsStream(),
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

              final cases = snapshot.data;

              if (cases == null || cases.isEmpty) {
                return const Center(
                  child: Text(
                    'Şu an duruşması süren bir dava bulunamadı.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: cases.length,
                itemBuilder: (context, index) {
                  return _CourtCaseCard(caseData: cases[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CourtCaseCard extends StatelessWidget {
  final Map<String, dynamic> caseData;
  // ignore: unused_element_parameter
  const _CourtCaseCard({super.key, required this.caseData});

  void _showCommentsPanel(BuildContext context, String postId) {
    final commentController = TextEditingController();
    final supabaseService = SupabaseService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'GÖLGE SAVUNMALARI',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabaseService.getCommentsStream(postId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.deepPurpleAccent,
                          ),
                        );
                      }
                      final comments = snapshot.data;
                      if (comments == null || comments.isEmpty) {
                        return const Center(
                          child: Text(
                            'Henüz bir savunma yapılmadı.',
                            style: TextStyle(
                              color: Colors.white38,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Anonim Jüri',
                              style: TextStyle(
                                color: Colors.deepPurpleAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              comments[index]['content'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const Divider(color: Colors.white10),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Savunmanı veya fikrini yaz...',
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: const Color(0xFF222222),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.deepPurpleAccent,
                      ),
                      onPressed: () async {
                        final text = commentController.text.trim();
                        if (text.isEmpty) return;
                        try {
                          await supabaseService.createComment(postId, text);
                          commentController.clear();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final supabaseService = SupabaseService();

    return Card(
      color: const Color(0xFF161616),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.redAccent, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DAVA DOSYASI #${caseData['id'].toString().substring(0, 5).toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const Icon(Icons.gavel, color: Colors.white38, size: 16),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              caseData['content'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabaseService.getVotesStream(caseData['id']),
              builder: (context, snapshot) {
                int light = 0;
                int shadow = 0;
                int myVote = 0;

                if (snapshot.hasData) {
                  final votes = snapshot.data!;
                  for (var vote in votes) {
                    if (vote['vote_type'] == 1) light++;
                    if (vote['vote_type'] == -1) shadow++;
                    if (vote['user_id'] == currentUserId) {
                      myVote = vote['vote_type'] as int;
                    }
                  }
                }

                int totalVotes = light + shadow;
                double lightRatio = totalVotes == 0 ? 0.5 : light / totalVotes;

                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: lightRatio,
                        minHeight: 8,
                        backgroundColor: Colors.deepPurpleAccent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.amber,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Işık: %${(lightRatio * 100).toStringAsFixed(0)} ($light)',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Gölge: %${((1 - lightRatio) * 100).toStringAsFixed(0)} ($shadow)',
                          style: const TextStyle(
                            color: Colors.deepPurpleAccent,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: myVote == 1
                                ? Colors.amber
                                : Colors.grey,
                          ),
                          icon: const Icon(Icons.wb_sunny, size: 18),
                          label: const Text('BERAAT'),
                          onPressed: () =>
                              supabaseService.castVote(caseData['id'], 1),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: myVote == -1
                                ? Colors.deepPurpleAccent
                                : Colors.grey,
                          ),
                          icon: const Icon(Icons.gavel, size: 18),
                          label: const Text('MAHKUMİYET'),
                          onPressed: () =>
                              supabaseService.castVote(caseData['id'], -1),
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.comment,
                            color: Colors.white54,
                            size: 20,
                          ),
                          tooltip: 'Savunmaları Gör',
                          onPressed: () =>
                              _showCommentsPanel(context, caseData['id']),
                        ),
                      ],
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
