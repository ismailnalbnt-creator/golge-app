import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'public_profile_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _postController = TextEditingController();
  final _supabaseService = SupabaseService();

  bool _isLoading = false;
  bool _isAnonymous = true;

  Future<void> _submitPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _supabaseService.createPost(
        content,
        isAnonymous: _isAnonymous,
        postType: 'feed',
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
    final bgColor = _isAnonymous ? Colors.black : const Color(0xFFF8F9FA);
    final topAreaColor = _isAnonymous ? const Color(0xFF0A0A0A) : Colors.white;
    final textColor = _isAnonymous ? Colors.white : Colors.black87;
    final inputBgColor = _isAnonymous
        ? const Color(0xFF161616)
        : const Color(0xFFF1F3F5);
    final hintColor = _isAnonymous ? Colors.white38 : Colors.black38;
    final borderColor = _isAnonymous ? Colors.white10 : Colors.black12;

    return Container(
      color: bgColor,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: topAreaColor,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _postController,
                  maxLength: 300,
                  maxLines: 3,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: _isAnonymous
                        ? 'Karanlığa bir sır fısılda... (Kimliğin gizli)'
                        : 'Herkesin göreceği bir şeyler yaz... (Açık kimlik)',
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
                          activeThumbColor: Colors.deepPurpleAccent,
                          inactiveThumbColor: Colors.orangeAccent,
                          // ignore: deprecated_member_use
                          inactiveTrackColor: Colors.orangeAccent.withOpacity(
                            0.3,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _isAnonymous = value;
                            });
                          },
                        ),
                        Icon(
                          _isAnonymous ? Icons.masks : Icons.wb_sunny,
                          color: _isAnonymous
                              ? Colors.deepPurpleAccent
                              : Colors.orangeAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isAnonymous ? 'Gölge Modu' : 'Açık Kimlik',
                          style: TextStyle(
                            color: _isAnonymous
                                ? Colors.deepPurpleAccent
                                : Colors.orangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAnonymous
                            ? Colors.deepPurpleAccent
                            : Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submitPost,
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
                              _isAnonymous ? Icons.stream : Icons.send,
                              size: 16,
                            ),
                      label: Text(_isAnonymous ? 'FISILDA' : 'PAYLAŞ'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabaseService.getFeedPostsStream(),
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
                  return Center(
                    child: Text(
                      'Akışta henüz bir hareket yok.',
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
                        ? const Color(0xFF161616)
                        : Colors.white;
                    // ignore: deprecated_member_use
                    final cardBorderColor = isPostAnonymous
                        // ignore: deprecated_member_use
                        ? Colors.deepPurpleAccent.withOpacity(0.4)
                        : Colors.grey.shade300;
                    final cardTextColor = isPostAnonymous
                        ? Colors.white
                        : Colors.black87;

                    return Card(
                      color: cardBgColor,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: isPostAnonymous ? 0 : 2,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: cardBorderColor, width: 1),
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
                                        color: Colors.deepPurpleAccent,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Anonim Gölge',
                                        style: TextStyle(
                                          color: Colors.deepPurpleAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
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
                            const SizedBox(height: 12),
                            Text(
                              post['content'] ?? '',
                              style: TextStyle(
                                color: cardTextColor,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.black12, height: 1),
                            const SizedBox(height: 4),
                            _PostActionFooter(
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

class _PostActionFooter extends StatelessWidget {
  final String postId;
  final bool isAnonymousCard;

  const _PostActionFooter({
    required this.postId,
    required this.isAnonymousCard,
  });

  void _showCommentsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CommentsBottomSheet(postId: postId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();
    final currentUser = Supabase.instance.client.auth.currentUser;
    final iconColor = isAnonymousCard ? Colors.white54 : Colors.black54;

    return Row(
      children: [
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabaseService.getLikesStream(postId),
          builder: (context, snapshot) {
            final likes = snapshot.data ?? [];
            final isLiked =
                currentUser != null &&
                likes.any((like) => like['user_id'] == currentUser.id);

            return Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.redAccent : iconColor,
                    size: 20,
                  ),
                  onPressed: () => supabaseService.toggleLike(postId),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                ),
                Text(
                  '${likes.length}',
                  style: TextStyle(color: iconColor, fontSize: 13),
                ),
              ],
            );
          },
        ),
        const SizedBox(width: 24),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: supabaseService.getCommentsStream(postId),
          builder: (context, snapshot) {
            final comments = snapshot.data ?? [];
            return Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: iconColor,
                    size: 20,
                  ),
                  onPressed: () => _showCommentsSheet(context),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                ),
                Text(
                  '${comments.length}',
                  style: TextStyle(color: iconColor, fontSize: 13),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CommentsBottomSheet extends StatefulWidget {
  final String postId;
  const _CommentsBottomSheet({required this.postId});

  @override
  State<_CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<_CommentsBottomSheet> {
  final _commentController = TextEditingController();
  final _supabaseService = SupabaseService();

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    await _supabaseService.createComment(widget.postId, text);
    _commentController.clear();
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
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Yorumlar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
                    child: CircularProgressIndicator(
                      color: Colors.deepPurpleAccent,
                    ),
                  );
                }

                final comments = snapshot.data!;
                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'İlk yorumu sen yap.',
                      style: TextStyle(color: Colors.white38),
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
                                  color: Colors.white54,
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
                                        color: Colors.deepPurpleAccent,
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
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Bir şeyler yaz...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
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
                  backgroundColor: Colors.deepPurpleAccent,
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
