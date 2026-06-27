import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class SirdasScreen extends StatefulWidget {
  const SirdasScreen({super.key});

  @override
  State<SirdasScreen> createState() => _SirdasScreenState();
}

class _SirdasScreenState extends State<SirdasScreen> {
  final _supabaseService = SupabaseService();
  final _myUserId = Supabase.instance.client.auth.currentUser!.id;

  // ==========================================
  // CANLI YORUM PENCERESİ (AŞAĞIDAN KAYARAK AÇILAN)
  // ==========================================
  void _showCommentsModal(String postId) {
    final commentController = TextEditingController();
    bool isPosting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(
        0xFF0A0A0A,
      ), // Sırdaş'a özel daha derin siyah
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 10),
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      'SIRDAŞ YORUMLARI',
                      style: TextStyle(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 20),

                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _supabaseService.getCommentsStream(postId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.tealAccent,
                              ),
                            );
                          }

                          final comments = snapshot.data ?? [];
                          if (comments.isEmpty) {
                            return const Center(
                              child: Text(
                                'Burada çok sessiz... İlk fısıldayan sen ol.',
                                style: TextStyle(color: Colors.white38),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];

                              // Sırdaş sayfasında yorumların hepsi gölgedir, veritabanına bakmaya gerek yok!
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.black,
                                      child: Icon(
                                        Icons.masks,
                                        color: Colors.tealAccent,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Gölge Kullanıcı',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comment['content'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
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

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        border: Border(top: BorderSide(color: Colors.white10)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Anonim olarak yorumla...',
                                hintStyle: const TextStyle(
                                  color: Colors.white38,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF1A1A1A),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: isPosting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.tealAccent,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send,
                                    color: Colors.tealAccent,
                                  ),
                            onPressed: isPosting
                                ? null
                                : () async {
                                    final text = commentController.text.trim();
                                    if (text.isEmpty) return;

                                    setModalState(() => isPosting = true);
                                    try {
                                      // Titanyum motor yorumu anında gölge olarak mühürler
                                      await _supabaseService.createComment(
                                        postId,
                                        text,
                                      );
                                      commentController.clear();
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Hata: $e')),
                                        );
                                      }
                                    } finally {
                                      if (context.mounted) {
                                        setModalState(() => isPosting = false);
                                      }
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // ZORUNLU ANONİM PAYLAŞIM PENCERESİ
  // ==========================================
  void _showNewSirdasPostModal() {
    final postController = TextEditingController();
    bool isPosting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SIRDAŞA İÇİNİ DÖK',
                        style: TextStyle(
                          color: Colors.tealAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: postController,
                    maxLines: 5,
                    maxLength:
                        500, // Sırdaş'ta insanlar daha uzun dertleşebilir, limiti yüksek tuttuk
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Kimse senin kim olduğunu bilmeyecek. Anlat...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      counterStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Burada maske değiştirme butonu YOK! Maske bu sayfada bedene yapışıktır.
                      const Row(
                        children: [
                          Icon(Icons.masks, color: Colors.tealAccent, size: 24),
                          SizedBox(width: 8),
                          Text(
                            '%100 Anonim',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.tealAccent, // Sırdaş'a özel teal rengi
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isPosting
                            ? null
                            : () async {
                                final text = postController.text.trim();
                                if (text.isEmpty) return;
                                setModalState(() => isPosting = true);
                                try {
                                  // isAnonymous: true ve postType: 'sirdas' ZORUNLU
                                  await _supabaseService.createPost(
                                    text,
                                    isAnonymous: true,
                                    postType: 'sirdas',
                                  );
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Hata: $e')),
                                    );
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setModalState(() => isPosting = false);
                                  }
                                }
                              },
                        child: isPosting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Fısılda',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Tam siyah arkaplan
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'SIRDAŞ',
          style: TextStyle(
            color: Colors.tealAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Colors.white10, height: 1),
        ),
      ),
      body: FutureBuilder<List<String>>(
        future: _supabaseService.getBlockListIds(),
        builder: (context, blockSnap) {
          final blockListIds = blockSnap.data ?? [];

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabaseService.getSirdasPostsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent),
                );
              }

              var allPosts = snapshot.data ?? [];
              var visiblePosts = allPosts
                  .where((p) => !blockListIds.contains(p['user_id']))
                  .toList();

              if (visiblePosts.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.nights_stay, color: Colors.white10, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Karanlık çok sessiz...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: visiblePosts.length,
                itemBuilder: (context, index) {
                  final post = visiblePosts[index];
                  final postId = post['id'];
                  final postUserId = post['user_id'];

                  return Card(
                    color: const Color(0xFF0A0A0A),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.white10),
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
                              const Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.black,
                                    child: Icon(
                                      Icons.masks,
                                      color: Colors.tealAccent,
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Gölge Kullanıcı",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white38,
                                  size: 20,
                                ),
                                color: const Color(0xFF1A1A1A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) async {
                                  if (value == 'report') {
                                    final reasonController =
                                        TextEditingController();
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        backgroundColor: const Color(
                                          0xFF121212,
                                        ),
                                        title: const Text(
                                          'Şikayet Et',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: TextField(
                                          controller: reasonController,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'Sebep...',
                                            hintStyle: TextStyle(
                                              color: Colors.white38,
                                            ),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text(
                                              'İptal',
                                              style: TextStyle(
                                                color: Colors.white38,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              if (reasonController.text
                                                  .trim()
                                                  .isEmpty) {
                                                return;
                                              }
                                              await _supabaseService.reportPost(
                                                postId: postId,
                                                reason: reasonController.text
                                                    .trim(),
                                              );
                                              if (context.mounted) {
                                                Navigator.pop(context);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('İletildi.'),
                                                    backgroundColor:
                                                        Colors.teal,
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text(
                                              'Gönder',
                                              style: TextStyle(
                                                color: Colors.tealAccent,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (value == 'block') {
                                    await _supabaseService.blockUser(
                                      postUserId,
                                    );
                                    setState(() {});
                                  }
                                },
                                itemBuilder: (BuildContext context) => [
                                  const PopupMenuItem<String>(
                                    value: 'report',
                                    child: Text(
                                      'Şikayet Et',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  if (postUserId != _myUserId)
                                    const PopupMenuItem<String>(
                                      value: 'block',
                                      child: Text(
                                        'Kullanıcıyı Engelle',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            post['content'] ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white10, height: 1),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              StreamBuilder<List<Map<String, dynamic>>>(
                                stream: _supabaseService.getLikesStream(postId),
                                builder: (context, likeSnapshot) {
                                  final likes = likeSnapshot.data ?? [];
                                  final isLiked = likes.any(
                                    (l) => l['user_id'] == _myUserId,
                                  );
                                  return Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isLiked
                                              ? Colors.redAccent
                                              : Colors.white38,
                                          size: 20,
                                        ),
                                        onPressed: () =>
                                            _supabaseService.toggleLike(postId),
                                      ),
                                      Text(
                                        '${likes.length}',
                                        style: TextStyle(
                                          color: isLiked
                                              ? Colors.redAccent
                                              : Colors.white38,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(width: 24),
                              StreamBuilder<List<Map<String, dynamic>>>(
                                stream: _supabaseService.getCommentsStream(
                                  postId,
                                ),
                                builder: (context, commentSnapshot) {
                                  final comments = commentSnapshot.data ?? [];
                                  return Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.chat_bubble_outline,
                                          color: Colors.white38,
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            _showCommentsModal(postId),
                                      ),
                                      Text(
                                        '${comments.length}',
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  );
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
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
        onPressed: _showNewSirdasPostModal,
        child: const Icon(Icons.edit),
      ),
    );
  }
}
