import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'public_profile_screen.dart';

class SirdasScreen extends StatefulWidget {
  const SirdasScreen({super.key});

  @override
  State<SirdasScreen> createState() => _SirdasScreenState();
}

class _SirdasScreenState extends State<SirdasScreen> {
  final _postController = TextEditingController();
  final _supabaseService = SupabaseService();

  bool _isLoading = false;
  bool _isAnonymous = true;

  Future<void> _submitSir() async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _supabaseService.createPost(
        content,
        isAnonymous: _isAnonymous,
        postType: 'sirdas',
      );
      _postController.clear();
      // ignore: use_build_context_synchronously
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isAnonymous
        ? const Color(0xFF040A0A)
        : const Color(0xFFECEFF1);
    final topAreaColor = _isAnonymous ? const Color(0xFF071212) : Colors.white;
    final textColor = _isAnonymous ? Colors.white : Colors.black87;
    final inputBgColor = _isAnonymous
        ? const Color(0xFF0B1A1A)
        : const Color(0xFFF8F9FA);
    final hintColor = _isAnonymous ? Colors.white38 : Colors.black45;
    // ignore: deprecated_member_use
    final borderColor = _isAnonymous
        // ignore: deprecated_member_use
        ? Colors.teal.withOpacity(0.3)
        : Colors.black12;

    return Container(
      color: bgColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: topAreaColor,
              border: Border(bottom: BorderSide(color: borderColor, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.nights_stay,
                      color: _isAnonymous ? Colors.tealAccent : Colors.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SIRDAŞ KÖŞESİ',
                      style: TextStyle(
                        color: _isAnonymous
                            ? Colors.tealAccent
                            : Colors.teal.shade800,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _postController,
                  maxLength: 400,
                  maxLines: 4,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: _isAnonymous
                        ? 'Karanlığa bir sır bırak, dertleşelim...'
                        : 'Açık kimliğinle bir meseleyi paylaş, fikir al...',
                    hintStyle: TextStyle(color: hintColor),
                    filled: true,
                    fillColor: inputBgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Switch(
                          value: _isAnonymous,
                          activeThumbColor: Colors.tealAccent,
                          inactiveThumbColor: Colors.blueGrey,
                          // ignore: deprecated_member_use
                          inactiveTrackColor: Colors.blueGrey.withOpacity(0.3),
                          onChanged: (value) {
                            setState(() {
                              _isAnonymous = value;
                            });
                          },
                        ),
                        Icon(
                          _isAnonymous ? Icons.masks : Icons.face,
                          color: _isAnonymous
                              ? Colors.tealAccent
                              : Colors.blueGrey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isAnonymous ? 'Gizli Sır' : 'Açık Sır',
                          style: TextStyle(
                            color: _isAnonymous
                                ? Colors.tealAccent
                                : Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAnonymous
                            ? Colors.teal.shade700
                            : Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submitSir,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _isAnonymous
                                  ? Icons.volunteer_activism
                                  : Icons.chat_bubble_outline,
                              size: 16,
                            ),
                      label: const Text('İÇİNİ DÖK'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabaseService.getSirdasPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent),
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
                  return Center(
                    child: Text(
                      'Şu an burada paylaşılan bir sır yok.',
                      style: TextStyle(
                        color: hintColor,
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

                    final cardBgColor = isPostAnonymous
                        ? const Color(0xFF081414)
                        : Colors.white;
                    // ignore: deprecated_member_use
                    final cardBorderColor = isPostAnonymous
                        // ignore: deprecated_member_use
                        ? Colors.teal.withOpacity(0.3)
                        : Colors.grey.shade400;
                    final cardTextColor = isPostAnonymous
                        ? Colors.white
                        : Colors.black87;

                    return Card(
                      color: cardBgColor,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      elevation: isPostAnonymous ? 0 : 4,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: cardBorderColor, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            isPostAnonymous
                                ? const Row(
                                    children: [
                                      Icon(
                                        Icons.masks,
                                        color: Colors.tealAccent,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Anonim Sır',
                                        style: TextStyle(
                                          color: Colors.tealAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  )
                                : FutureBuilder<Map<String, dynamic>?>(
                                    future: _supabaseService.getProfileById(
                                      post['user_id'],
                                    ),
                                    builder: (context, profileSnapshot) {
                                      final profile = profileSnapshot.data;
                                      final name = profile != null
                                          ? "${profile['first_name']} ${profile['last_name']}"
                                          : "Kullanıcı";
                                      final username = profile != null
                                          ? "@${profile['username']}"
                                          : "";

                                      return GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PublicProfileScreen(
                                                    userId: post['user_id'],
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.account_circle,
                                              color: Colors.blueGrey,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              username,
                                              style: const TextStyle(
                                                color: Colors.blueGrey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                            const SizedBox(height: 16),

                            Text(
                              post['content'] ?? '',
                              style: TextStyle(
                                color: cardTextColor,
                                fontSize: 16,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 20),
                            const Divider(color: Colors.black12, height: 1),
                            const SizedBox(height: 8),

                            _SirdasPostFooter(
                              postId: post['id'],
                              isAnonymousCard: isPostAnonymous,
                            ),
                          ],
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

class _SirdasPostFooter extends StatelessWidget {
  final String postId;
  final bool isAnonymousCard;

  const _SirdasPostFooter({
    required this.postId,
    required this.isAnonymousCard,
  });

  void _showSirdasCommentsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SirdasCommentsBottomSheet(postId: postId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();
    final currentUser = Supabase.instance.client.auth.currentUser;
    final textColor = isAnonymousCard ? Colors.white70 : Colors.black87;
    // ignore: deprecated_member_use
    final iconColor = isAnonymousCard
        // ignore: deprecated_member_use
        ? Colors.tealAccent.withOpacity(0.7)
        : Colors.teal;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabaseService.getVotesStream(postId),
      builder: (context, snapshot) {
        int supportVotes = 0;
        int realisticVotes = 0;
        int userVote = 0;

        if (snapshot.hasData) {
          for (var vote in snapshot.data!) {
            if (vote['vote_type'] == 1) supportVotes++;
            if (vote['vote_type'] == -1) realisticVotes++;
            if (currentUser != null && vote['user_id'] == currentUser.id) {
              userVote = vote['vote_type'];
            }
          }
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => supabaseService.castVote(postId, 1),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      userVote == 1
                          ? Icons.volunteer_activism
                          : Icons.volunteer_activism_outlined,
                      color: userVote == 1 ? Colors.tealAccent : textColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$supportVotes Yanındayım',
                      style: TextStyle(
                        color: userVote == 1 ? Colors.tealAccent : textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              width: 1,
              height: 18,
              color: isAnonymousCard ? Colors.white10 : Colors.black12,
            ),

            InkWell(
              onTap: () => supabaseService.castVote(postId, -1),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      userVote == -1 ? Icons.psychology : Icons.psychology_alt,
                      color: userVote == -1 ? Colors.orangeAccent : textColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$realisticVotes Gerçekçi Bak',
                      style: TextStyle(
                        color: userVote == -1 ? Colors.orangeAccent : textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              width: 1,
              height: 18,
              color: isAnonymousCard ? Colors.white10 : Colors.black12,
            ),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabaseService.getCommentsStream(postId),
              builder: (context, commentSnapshot) {
                final commentCount = commentSnapshot.data?.length ?? 0;
                return InkWell(
                  onTap: () => _showSirdasCommentsSheet(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: iconColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$commentCount Fikir',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _SirdasCommentsBottomSheet extends StatefulWidget {
  final String postId;
  const _SirdasCommentsBottomSheet({required this.postId});

  @override
  State<_SirdasCommentsBottomSheet> createState() =>
      _SirdasCommentsBottomSheetState();
}

class _SirdasCommentsBottomSheetState
    extends State<_SirdasCommentsBottomSheet> {
  final _commentController = TextEditingController();
  final _supabaseService = SupabaseService();

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    try {
      await _supabaseService.createComment(widget.postId, text);
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Yorum iletilemedi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Fikirler ve Tavsiyeler',
            style: TextStyle(
              color: Colors.tealAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabaseService.getCommentsStream(widget.postId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent),
                  );
                }

                final comments = snapshot.data!;
                if (comments.isEmpty) {
                  // HATA DÜZELTİLDİ: textAlign: TextAlign.center olarak değiştirildi.
                  return const Center(
                    child: Text(
                      'Bu sırra henüz kimse fikir belirtmedi. İlk tavsiyeyi sen ver.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _supabaseService.getProfileById(
                        comment['user_id'],
                      ),
                      builder: (context, profileSnap) {
                        final name =
                            profileSnap.data?['first_name'] ?? 'Kullanıcı';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.white10,
                                child: Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Colors.tealAccent,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.tealAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      comment['content'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
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

          const Divider(color: Colors.white10, height: 1),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Bir tavsiye veya destek yaz...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF142424),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _sendComment,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
