import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'public_profile_screen.dart'; // Profil sayfasına yönlendirme için import eklendi

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _supabaseService = SupabaseService();
  final _myUserId = Supabase.instance.client.auth.currentUser!.id;

  // ==========================================
  // CANLI YORUM PENCERESİ
  // ==========================================
  void _showCommentsModal(String postId) {
    final commentController = TextEditingController();
    bool isPosting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
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
                      'YORUMLAR',
                      style: TextStyle(
                        color: Colors.white,
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
                                color: Colors.deepPurpleAccent,
                              ),
                            );
                          }

                          final comments = snapshot.data ?? [];
                          if (comments.isEmpty) {
                            return const Center(
                              child: Text(
                                'İlk yorumu sen yap!',
                                style: TextStyle(color: Colors.white38),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              final isAnon = comment['is_anonymous'] ?? false;
                              final commentUserId = comment['user_id'];

                              return FutureBuilder<Map<String, dynamic>?>(
                                future: _supabaseService.getProfileById(
                                  commentUserId,
                                ),
                                builder: (context, profSnap) {
                                  final profile = profSnap.data;
                                  final fullName = isAnon
                                      ? 'Gölge Kullanıcı'
                                      : "${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}";
                                  final username = isAnon
                                      ? ''
                                      : "@${profile?['username'] ?? ''}";

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: isAnon
                                              ? Colors.black
                                              : const Color(0xFF1A1A1A),
                                          child: Icon(
                                            isAnon ? Icons.masks : Icons.person,
                                            color: isAnon
                                                ? Colors.white38
                                                : Colors.tealAccent,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    fullName.trim().isEmpty
                                                        ? "İsimsiz"
                                                        : fullName,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  if (!isAnon &&
                                                      username.length > 1)
                                                    Text(
                                                      username,
                                                      style: const TextStyle(
                                                        color: Colors.white38,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                ],
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
                                hintText: 'Yorum ekle...',
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
                                      color: Colors.deepPurpleAccent,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send,
                                    color: Colors.deepPurpleAccent,
                                  ),
                            onPressed: isPosting
                                ? null
                                : () async {
                                    final text = commentController.text.trim();
                                    if (text.isEmpty) return;

                                    setModalState(() => isPosting = true);
                                    try {
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
  // YENİ GÖNDERİ PAYLAŞMA PENCERESİ
  // ==========================================
  void _showNewPostModal() {
    final postController = TextEditingController();
    bool isPosting = false;
    bool isAnonymous = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
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
                        'YENİ PAYLAŞIM',
                        style: TextStyle(
                          color: Colors.white,
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
                    maxLines: 4,
                    maxLength: 280,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Neler düşünüyorsun?\n(Etiket için # kullan)',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      counterStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isAnonymous ? Icons.masks : Icons.masks_outlined,
                              color: isAnonymous
                                  ? Colors.tealAccent
                                  : Colors.white38,
                              size: 28,
                            ),
                            onPressed: () {
                              setModalState(() {
                                isAnonymous = !isAnonymous;
                              });
                            },
                          ),
                          if (isAnonymous)
                            const Text(
                              'Gölge Modu Aktif',
                              style: TextStyle(
                                color: Colors.tealAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
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
                                  await _supabaseService.createPost(
                                    text,
                                    isAnonymous: isAnonymous,
                                    postType: 'feed',
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
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'PAYLAŞ',
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(
                  bottom: BorderSide(color: Colors.white10, width: 1),
                ),
              ),
              child: const TabBar(
                indicatorColor: Colors.deepPurpleAccent,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
                tabs: [
                  Tab(text: 'GENEL'),
                  Tab(text: 'TAKİP EDİLENLER'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [_buildGeneralFeed(), _buildFollowingFeed()],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepPurpleAccent,
          onPressed: _showNewPostModal,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  // ==========================================
  // 1. SEKME: GENEL AKIŞ
  // ==========================================
  Widget _buildGeneralFeed() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('posts')
          .stream(primaryKey: ['id'])
          .eq('post_type', 'feed'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
          );
        }
        var posts = snapshot.data;
        if (posts == null || posts.isEmpty) {
          return const Center(
            child: Text(
              'Burada henüz yaprak kıpırdamıyor.',
              style: TextStyle(color: Colors.white38),
            ),
          );
        }

        posts.sort(
          (a, b) => DateTime.parse(
            b['created_at'],
          ).compareTo(DateTime.parse(a['created_at'])),
        );
        return _buildPostList(posts);
      },
    );
  }

  // ==========================================
  // 2. SEKME: TAKİP EDİLENLER AKIŞI
  // ==========================================
  Widget _buildFollowingFeed() {
    return FutureBuilder<List<String>>(
      future: _supabaseService.getMyFollowingIds(),
      builder: (context, followSnap) {
        if (followSnap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
          );
        }

        final followingIds = followSnap.data ?? [];

        if (followingIds.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_search, color: Colors.white10, size: 64),
                SizedBox(height: 16),
                Text(
                  'Henüz kimseyi takip etmiyorsun.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Genel akıştan yeni gölgeler keşfet!',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: Supabase.instance.client
              .from('posts')
              .stream(primaryKey: ['id'])
              .eq('post_type', 'feed'),
          builder: (context, postSnap) {
            if (postSnap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.deepPurpleAccent,
                ),
              );
            }

            var allPosts = postSnap.data ?? [];
            var followingPosts = allPosts
                .where((post) => followingIds.contains(post['user_id']))
                .toList();

            if (followingPosts.isEmpty) {
              return const Center(
                child: Text(
                  'Takip ettiğin kişiler henüz bir şey paylaşmadı.',
                  style: TextStyle(color: Colors.white38),
                ),
              );
            }

            followingPosts.sort(
              (a, b) => DateTime.parse(
                b['created_at'],
              ).compareTo(DateTime.parse(a['created_at'])),
            );
            return _buildPostList(followingPosts);
          },
        );
      },
    );
  }

  // ==========================================
  // YARDIMCI GÖNDERİ KARTLARI LİSTESİ
  // ==========================================
  Widget _buildPostList(List<Map<String, dynamic>> posts) {
    return FutureBuilder<List<String>>(
      future: _supabaseService.getBlockListIds(),
      builder: (context, blockSnap) {
        final blockListIds = blockSnap.data ?? [];
        var visiblePosts = posts
            .where((p) => !blockListIds.contains(p['user_id']))
            .toList();

        if (visiblePosts.isEmpty) {
          return const Center(
            child: Text(
              'Gösterilecek içerik bulunamadı.',
              style: TextStyle(color: Colors.white38),
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
            final isAnon = post['is_anonymous'] ?? false;
            return FutureBuilder<Map<String, dynamic>?>(
              future: _supabaseService.getProfileById(postUserId),
              builder: (context, profSnap) {
                final profile = profSnap.data;
                final fullName = isAnon
                    ? 'Gölge Kullanıcı'
                    : "${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}";
                final username = isAnon ? '' : "@${profile?['username'] ?? ''}";

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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              // --- TAMİR EDİLEN KISIM: ANONİM DEĞİLSE PROFİLE YÖNLENDİRİR ---
                              onTap: () {
                                if (!isAnon) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PublicProfileScreen(
                                        userId: postUserId,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: isAnon
                                        ? Colors.black
                                        : const Color(0xFF1A1A1A),
                                    child: Icon(
                                      isAnon ? Icons.masks : Icons.person,
                                      color: isAnon
                                          ? Colors.white38
                                          : Colors.tealAccent,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fullName.trim().isEmpty
                                            ? "İsimsiz"
                                            : fullName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (!isAnon && username.length > 1)
                                        Text(
                                          username,
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            Row(
                              children: [
                                if (postUserId != _myUserId && !isAnon)
                                  FutureBuilder<List<String>>(
                                    future: _supabaseService
                                        .getMyFollowingIds(),
                                    builder: (context, followingSnap) {
                                      final myFollowings =
                                          followingSnap.data ?? [];
                                      final isFollowing = myFollowings.contains(
                                        postUserId,
                                      );
                                      return OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                          minimumSize: Size.zero,
                                          side: BorderSide(
                                            color: isFollowing
                                                ? Colors.white10
                                                : Colors.deepPurpleAccent,
                                          ),
                                        ),
                                        onPressed: () async {
                                          await _supabaseService.toggleFollow(
                                            postUserId,
                                          );
                                          setState(() {});
                                        },
                                        child: Text(
                                          isFollowing
                                              ? 'Takiptesin'
                                              : 'Takip Et',
                                          style: TextStyle(
                                            color: isFollowing
                                                ? Colors.white38
                                                : Colors.deepPurpleAccent,
                                            fontSize: 11,
                                          ),
                                        ),
                                      );
                                    },
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
                                            'Gönderiyi Şikayet Et',
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
                                              hintText:
                                                  'Şikayet sebebini yazın...',
                                              hintStyle: TextStyle(
                                                color: Colors.white38,
                                              ),
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.white10,
                                                    ),
                                                  ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors
                                                          .deepPurpleAccent,
                                                    ),
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
                                                await _supabaseService
                                                    .reportPost(
                                                      postId: postId,
                                                      reason: reasonController
                                                          .text
                                                          .trim(),
                                                    );
                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Şikayetiniz iletildi.',
                                                      ),
                                                      backgroundColor:
                                                          Colors.teal,
                                                    ),
                                                  );
                                                }
                                              },
                                              child: const Text(
                                                'Gönder',
                                                style: TextStyle(
                                                  color:
                                                      Colors.deepPurpleAccent,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } else if (value == 'block') {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: const Color(
                                            0xFF121212,
                                          ),
                                          title: const Text(
                                            'Kullanıcıyı Engelle',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                          content: const Text(
                                            'Bu kullanıcıyı engellemek istediğinize emin misiniz?',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
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
                                                await _supabaseService
                                                    .blockUser(postUserId);
                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Kullanıcı engellendi.',
                                                      ),
                                                      backgroundColor:
                                                          Colors.redAccent,
                                                    ),
                                                  );
                                                  setState(() {});
                                                }
                                              },
                                              child: const Text(
                                                'Engelle',
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
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
                          ],
                        ),
                        const SizedBox(height: 12),
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
                                        size: 18,
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
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(width: 16),
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
    );
  }
}
