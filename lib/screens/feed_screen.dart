import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'public_profile_screen.dart'; 
import '../widgets/smart_text.dart'; // SİHİRLİ METİN MOTORU BAĞLANDI

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
  // ==========================================
  // CANLI YORUM PENCERESİ (AKILLI @ MOTORU İLE)
  // ==========================================
  void _showCommentsModal(String postId) {
    final commentController = TextEditingController();
    bool isPosting = false;

    // --- MENTION (BAHSETME) DEĞİŞKENLERİ ---
    List<Map<String, dynamic>> searchResults = [];
    bool showMentionList = false;
    final client = Supabase.instance.client;

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
            
            // --- YORUM METNİNİ DİNLEYEN RADAR ---
            void onCommentTextChanged(String text) async {
              final cursorPosition = commentController.selection.base.offset;
              if (cursorPosition == -1) return;

              final textBeforeCursor = text.substring(0, cursorPosition);
              // Sonda @ ve ardından gelen harfleri yakalayan kural
              final mentionMatch = RegExp(r'@([a-zA-Z0-9_]*)$').firstMatch(textBeforeCursor);

              if (mentionMatch != null) {
                final query = mentionMatch.group(1) ?? '';
                setModalState(() => showMentionList = true);

                try {
                  // Görünür kullanıcıları filtrele
                  var response = client
                      .from('profiles')
                      .select('username, first_name, last_name, is_shadow_mode')
                      .eq('is_shadow_mode', false);

                  if (query.isNotEmpty) {
                    response = response.ilike('username', '%$query%');
                  }

                  final data = await response.limit(4);
                  if (context.mounted) {
                    setModalState(() {
                      searchResults = List<Map<String, dynamic>>.from(data);
                    });
                  }
                } catch (e) {
                  debugPrint("Yorum arama hatası: $e");
                }
              } else {
                setModalState(() {
                  showMentionList = false;
                  searchResults = [];
                });
              }
            }

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

                    // --- YORUMLAR LİSTESİ ---
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _supabaseService.getCommentsStream(postId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
                            );
                          }

                          final comments = snapshot.data ?? [];
                          if (comments.isEmpty) {
                            return const Center(
                              child: Text('İlk yorumu sen yap!', style: TextStyle(color: Colors.white38)),
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
                                future: _supabaseService.getProfileById(commentUserId),
                                builder: (context, profSnap) {
                                  final profile = profSnap.data;
                                  final fullName = isAnon
                                      ? 'Gölge Kullanıcı'
                                      : "${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}";
                                  final username = isAnon ? '' : "@${profile?['username'] ?? ''}";

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: isAnon ? Colors.black : const Color(0xFF1A1A1A),
                                          child: Icon(
                                            isAnon ? Icons.masks : Icons.person,
                                            color: isAnon ? Colors.white38 : Colors.tealAccent,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    fullName.trim().isEmpty ? "İsimsiz" : fullName,
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  if (!isAnon && username.length > 1)
                                                    Text(username, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              SmartText(
                                                text: comment['content'] ?? '',
                                                style: const TextStyle(color: Colors.white70, fontSize: 13),
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

                    // --- YORUM İÇİN AÇILIR KULLANICI LİSTESİ PANELİ ---
                    if (showMentionList && searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final user = searchResults[index];
                            final username = user['username'] ?? 'isimsiz';
                            final fullName = "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}";

                            return ListTile(
                              leading: const CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.black,
                                child: Icon(Icons.person, color: Colors.tealAccent, size: 16),
                              ),
                              title: Text(username, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              subtitle: Text(fullName.trim(), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              onTap: () {
                                final currentText = commentController.text;
                                final cursorPosition = commentController.selection.base.offset;
                                final textBeforeCursor = currentText.substring(0, cursorPosition);
                                final textAfterCursor = currentText.substring(cursorPosition);
                                
                                final replaceRegex = RegExp(r'@([a-zA-Z0-9_]*)$');
                                final newTextBefore = textBeforeCursor.replaceAll(replaceRegex, '@$username ');
                                
                                commentController.text = newTextBefore + textAfterCursor;
                                commentController.selection = TextSelection.collapsed(offset: newTextBefore.length);
                                
                                setModalState(() {
                                  showMentionList = false;
                                  searchResults = [];
                                });
                              },
                            );
                          },
                        ),
                      ),

                    // --- ALT INPUT GİRİŞ ALANI ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        border: Border(top: BorderSide(color: Colors.white10)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              onChanged: onCommentTextChanged, // Radarı buraya da bağladık
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Yorum ekle... (@kullanici)',
                                hintStyle: const TextStyle(color: Colors.white38),
                                filled: true,
                                fillColor: const Color(0xFF1A1A1A),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                    child: CircularProgressIndicator(color: Colors.deepPurpleAccent, strokeWidth: 2),
                                  )
                                : const Icon(Icons.send, color: Colors.deepPurpleAccent),
                            onPressed: isPosting
                                ? null
                                : () async {
                                    final text = commentController.text.trim();
                                    if (text.isEmpty) return;

                                    setModalState(() => isPosting = true);
                                    try {
                                      await _supabaseService.createComment(postId, text);
                                      commentController.clear();
                                      setModalState(() {
                                        showMentionList = false;
                                        searchResults = [];
                                      });
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
  // ==========================================
  // YENİ GÖNDERİ PAYLAŞMA PENCERESİ (AKILLI @ MOTORU İLE)
  // ==========================================
  void _showNewPostModal() {
    final postController = TextEditingController();
    bool isPosting = false;
    bool isAnonymous = false;

    // --- MENTION (BAHSETME) DEĞİŞKENLERİ ---
    List<Map<String, dynamic>> searchResults = [];
    bool showMentionList = false;
    final client = Supabase.instance.client;

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
            
            // --- METNİ DİNLEYEN CANLI RADAR ---
            void onTextChanged(String text) async {
              final cursorPosition = postController.selection.base.offset;
              if (cursorPosition == -1) return;

              final textBeforeCursor = text.substring(0, cursorPosition);
              // Sonda @ ve ardından gelen harfleri yakalayan kural
              final mentionMatch = RegExp(r'@([a-zA-Z0-9_]*)$').firstMatch(textBeforeCursor);

              if (mentionMatch != null) {
                final query = mentionMatch.group(1) ?? '';
                setModalState(() => showMentionList = true);

                try {
                  // Gölge modunda OLMAYAN kullanıcıları getir
                  var response = client
                      .from('profiles')
                      .select('username, first_name, last_name, is_shadow_mode')
                      .eq('is_shadow_mode', false);

                  if (query.isNotEmpty) {
                    response = response.ilike('username', '%$query%');
                  }

                  // En fazla 4 kişi göster ki ekranı boğmasın
                  final data = await response.limit(4);
                  if (context.mounted) {
                    setModalState(() {
                      searchResults = List<Map<String, dynamic>>.from(data);
                    });
                  }
                } catch (e) {
                  debugPrint("Arama hatası: $e");
                }
              } else {
                setModalState(() {
                  showMentionList = false;
                  searchResults = [];
                });
              }
            }

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
                    onChanged: onTextChanged, // Radarı metin kutusuna bağladık
                    maxLines: 4,
                    maxLength: 280,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Neler düşünüyorsun?\n(@ koyarak birinden bahset)',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      counterStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                  
                  // --- AÇILIR KULLANICI LİSTESİ ---
                  if (showMentionList && searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final user = searchResults[index];
                          final username = user['username'] ?? 'isimsiz';
                          final fullName = "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}";

                          return ListTile(
                            leading: const CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.black,
                              child: Icon(Icons.person, color: Colors.tealAccent, size: 16),
                            ),
                            title: Text(username, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text(fullName.trim(), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            onTap: () {
                              // Tıklanan kişiyi metin kutusunun içine otomatik yaz
                              final currentText = postController.text;
                              final cursorPosition = postController.selection.base.offset;
                              final textBeforeCursor = currentText.substring(0, cursorPosition);
                              final textAfterCursor = currentText.substring(cursorPosition);
                              
                              final replaceRegex = RegExp(r'@([a-zA-Z0-9_]*)$');
                              final newTextBefore = textBeforeCursor.replaceAll(replaceRegex, '@$username ');
                              
                              postController.text = newTextBefore + textAfterCursor;
                              postController.selection = TextSelection.collapsed(offset: newTextBefore.length);
                              
                              setModalState(() {
                                showMentionList = false;
                                searchResults = [];
                              });
                            },
                          );
                        },
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
                              color: isAnonymous ? Colors.tealAccent : Colors.white38,
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
  heroTag: 'feed_main_fab', // <--- SADECE BU SATIRI EKLE
  backgroundColor: Colors.deepPurpleAccent,
  onPressed: _showNewPostModal,
  child: const Icon(Icons.add, color: Colors.white),
),
      ),
    );
  }

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
          (a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])),
        );
        return _buildPostList(posts);
      },
    );
  }

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
              (a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])),
            );
            return _buildPostList(followingPosts);
          },
        );
      },
    );
  }

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
                                    backgroundColor: isAnon ? Colors.black : const Color(0xFF1A1A1A),
                                    child: Icon(
                                      isAnon ? Icons.masks : Icons.person,
                                      color: isAnon ? Colors.white38 : Colors.tealAccent,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fullName.trim().isEmpty ? "İsimsiz" : fullName,
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
                                    future: _supabaseService.getMyFollowingIds(),
                                    builder: (context, followingSnap) {
                                      final myFollowings = followingSnap.data ?? [];
                                      final isFollowing = myFollowings.contains(postUserId);
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
                                          await _supabaseService.toggleFollow(postUserId);
                                          setState(() {});
                                        },
                                        child: Text(
                                          isFollowing ? 'Takiptesin' : 'Takip Et',
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
                                      // Şikayet kodu (öncekiyle aynı)
                                    } else if (value == 'block') {
                                      // Engelleme kodu (öncekiyle aynı)
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
                        
                        // GÖNDERİ METNİ İÇİN AKILLI METİN MOTORU
                        SmartText(
                          text: post['content'] ?? '',
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
                                final isLiked = likes.any((l) => l['user_id'] == _myUserId);
                                return Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: isLiked ? Colors.redAccent : Colors.white38,
                                        size: 18,
                                      ),
                                      onPressed: () => _supabaseService.toggleLike(postId),
                                    ),
                                    Text(
                                      '${likes.length}',
                                      style: TextStyle(
                                        color: isLiked ? Colors.redAccent : Colors.white38,
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
                              stream: _supabaseService.getCommentsStream(postId),
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
                                      onPressed: () => _showCommentsModal(postId),
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