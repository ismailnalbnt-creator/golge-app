import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class HashtagDetailScreen extends StatefulWidget {
  final String hashtag;

  const HashtagDetailScreen({super.key, required this.hashtag});

  @override
  State<HashtagDetailScreen> createState() => _HashtagDetailScreenState();
}

class _HashtagDetailScreenState extends State<HashtagDetailScreen> {
  final _supabaseService = SupabaseService();
  late TextEditingController _postController;
  final _myUserId = Supabase.instance.client.auth.currentUser!.id;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _postController = TextEditingController(text: '#${widget.hashtag} ');
  }

  Future<void> _sharePost() async {
    final text = _postController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      await _supabaseService.createPost(
        text,
        isAnonymous: false,
        postType: 'feed',
      );
      if (mounted) {
        _postController.text = '#${widget.hashtag} ';
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  // --- YORUMLAR İÇİN AŞAĞIDAN AÇILAN PENCERE (BOTTOM SHEET) ---
  void _showCommentsBottomSheet(String postId) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Klavyenin pencereyi yukarı itmesi için
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tutamaç çizgisi
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      'YORUMLAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white10),

                    // Canlı Yorum Listesi
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _supabaseService.getCommentsStream(postId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.deepPurpleAccent,
                              ),
                            );
                          }
                          final comments = snapshot.data ?? [];
                          if (comments.isEmpty) {
                            return const Center(
                              child: Text(
                                'Henüz yorum yapılmamış. İlk yorumu sen yaz!',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];

                              return FutureBuilder<Map<String, dynamic>?>(
                                future: _supabaseService.getProfileById(
                                  comment['user_id'],
                                ),
                                builder: (context, profSnap) {
                                  final profile = profSnap.data;
                                  final commenterName = profile != null
                                      ? "${profile['first_name']} ${profile['last_name']}"
                                      : "Gölge Kullanıcı";

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 12.0,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.white10,
                                          child: Icon(
                                            Icons.person,
                                            size: 14,
                                            color: Colors.white54,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                commenterName,
                                                style: const TextStyle(
                                                  color:
                                                      Colors.deepPurpleAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                comment['content'] ?? '',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  height: 1.3,
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
                          );
                        },
                      ),
                    ),

                    // Yorum Yazma Giriş Alanı
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A1A1A),
                        border: Border(top: BorderSide(color: Colors.white10)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Bir şeyler mırıldan...',
                                hintStyle: const TextStyle(
                                  color: Colors.white38,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF262626),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: Colors.deepPurpleAccent,
                            radius: 18,
                            child: IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 16,
                              ),
                              onPressed: () async {
                                final text = commentController.text.trim();
                                if (text.isEmpty) return;
                                commentController.clear();
                                await _supabaseService.createComment(
                                  postId,
                                  text,
                                );
                              },
                            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '#${widget.hashtag.toUpperCase()}',
          style: const TextStyle(
            color: Colors.deepPurpleAccent,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 1,
      ),
      body: Column(
        children: [
          // GÖNDERİ LİSTESİ
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabaseService.getPostsByHashtagStream(widget.hashtag),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepPurpleAccent,
                    ),
                  );
                }

                final posts = snapshot.data;
                if (posts == null || posts.isEmpty) {
                  return const Center(
                    child: Text(
                      'Bu etiketle henüz kimse konuşmamış. İlk sen ol!',
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final postId = post['id'];
                    final isAnon = post['is_anonymous'] ?? false;

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _supabaseService.getProfileById(post['user_id']),
                      builder: (context, profSnap) {
                        final profile = profSnap.data;
                        final fullName = isAnon
                            ? 'Gölge Kullanıcı'
                            : "${profile?['first_name'] ?? 'Yükleniyor...'} ${profile?['last_name'] ?? ''}";
                        final username = isAnon
                            ? ''
                            : "@${profile?['username'] ?? ''}";

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
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Üst Satır: Profil Bilgisi
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: isAnon
                                          ? Colors.black
                                          : const Color(0xFF1A1A1A),
                                      child: Icon(
                                        isAnon ? Icons.masks : Icons.person,
                                        color: isAnon
                                            ? Colors.white38
                                            : Colors.tealAccent,
                                        size: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fullName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (!isAnon && username.length > 1)
                                          Text(
                                            username,
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Orta Kısım: Gönderi Metni
                                Text(
                                  post['content'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Divider(color: Colors.white10, height: 1),
                                const SizedBox(height: 4),
                                // Alt Kısım: Beğeni ve Yorum Butonları (CANLI)
                                Row(
                                  children: [
                                    // 1. CANLI BEĞENİ BUTONU
                                    StreamBuilder<List<Map<String, dynamic>>>(
                                      stream: _supabaseService.getLikesStream(
                                        postId,
                                      ),
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
                                                size: 18,
                                              ),
                                              onPressed: () => _supabaseService
                                                  .toggleLike(postId),
                                            ),
                                            Text(
                                              '${likes.length}',
                                              style: TextStyle(
                                                color: isLiked
                                                    ? Colors.redAccent
                                                    : Colors.white38,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 16),
                                    // 2. CANLI YORUM BUTONU
                                    StreamBuilder<List<Map<String, dynamic>>>(
                                      stream: _supabaseService
                                          .getCommentsStream(postId),
                                      builder: (context, commentSnapshot) {
                                        final comments =
                                            commentSnapshot.data ?? [];

                                        return Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.chat_bubble_outline,
                                                color: Colors.white38,
                                                size: 18,
                                              ),
                                              onPressed: () =>
                                                  _showCommentsBottomSheet(
                                                    postId,
                                                  ),
                                            ),
                                            Text(
                                              '${comments.length}',
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 12,
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
          ),

          // BU ETİKETE ÖZEL PAYLAŞIM GİRİŞ ALANI
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF121212),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _postController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Bu konu hakkında bir şeyler yaz...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _isPosting
                    ? const CircularProgressIndicator(
                        color: Colors.deepPurpleAccent,
                      )
                    : CircleAvatar(
                        backgroundColor: Colors.deepPurpleAccent,
                        child: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 18,
                          ),
                          onPressed: _sharePost,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
