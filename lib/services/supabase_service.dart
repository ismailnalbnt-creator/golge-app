import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final client = Supabase.instance.client;

  // --- KİMLİK DOĞRULAMA (AUTH) İŞLEMLERİ ---
  Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // --- PROFİL VE KONUM (RADAR) İŞLEMLERİ ---
  Future<void> createProfile({
    required String firstName,
    required String lastName,
    required String username,
    required DateTime birthDate,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Önce kayıt olmalısın.');

    await client.from('profiles').insert({
      'id': user.id,
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'birth_date': birthDate.toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> getProfileById(String userId) async {
    return await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  Future<void> updateLocationVisibility(
    bool isVisible, {
    double? lat,
    double? lng,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    await client
        .from('profiles')
        .update({'is_location_visible': isVisible, 'lat': lat, 'lng': lng})
        .eq('id', user.id);
  }

  Stream<List<Map<String, dynamic>>> getVisibleUsersStream() {
    return client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map(
          (profiles) =>
              profiles.where((p) => p['is_location_visible'] == true).toList(),
        );
  }

  // --- GÖNDERİ İŞLEMLERİ (AKIŞ VE SIRDAŞ - KÜRESEL GÖLGE EKLENDİ) ---
  Future<void> createPost(
    String content, {
    bool isAnonymous = false,
    String postType = 'feed',
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Giriş yapmalısın.');

    final profile = await client
        .from('profiles')
        .select('is_shadow_mode')
        .eq('id', user.id)
        .maybeSingle();
    final bool isGlobalShadowActive = profile?['is_shadow_mode'] ?? false;
    final bool finalAnonymous = isGlobalShadowActive || isAnonymous;

    await client.from('posts').insert({
      'user_id': user.id,
      'content': content,
      'is_anonymous': finalAnonymous,
      'post_type': postType,
    });
  }

  Future<void> deletePost(String postId) async {
    final user = client.auth.currentUser;
    if (user == null) return;
    await client.from('posts').delete().eq('id', postId).eq('user_id', user.id);
  }

  Stream<List<Map<String, dynamic>>> getFeedPostsStream() {
    return client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (posts) => posts
              .where(
                (post) =>
                    post['post_type'] == 'feed' || post['post_type'] == null,
              )
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getSirdasPostsStream() {
    return client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (posts) =>
              posts.where((post) => post['post_type'] == 'sirdas').toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getMyPostsStream() {
    final user = client.auth.currentUser;
    if (user == null) return const Stream.empty();
    return client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (posts) => posts.where((post) => post['user_id'] == user.id).toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> getUserPublicPostsStream(String userId) {
    return client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (posts) => posts
              .where(
                (post) =>
                    post['user_id'] == userId && post['is_anonymous'] == false,
              )
              .toList(),
        );
  }

  // --- BEĞENİ İŞLEMLERİ ---
  Future<void> toggleLike(String postId) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Beğenmek için giriş yapmalısın.');

    final existingLike = await client
        .from('likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existingLike != null) {
      await client.from('likes').delete().eq('id', existingLike['id']);
    } else {
      await client.from('likes').insert({
        'post_id': postId,
        'user_id': user.id,
      });

      final postData = await client
          .from('posts')
          .select('user_id')
          .eq('id', postId)
          .maybeSingle();
      if (postData != null && postData['user_id'] != user.id) {
        await sendNotification(
          targetUserId: postData['user_id'] as String,
          type: 'like',
          content: 'Bir gölge gönderini beğendi.',
        );
      }
    }
  }

  Stream<List<Map<String, dynamic>>> getLikesStream(String postId) {
    return client.from('posts').stream(primaryKey: ['id']).asyncMap((_) async {
      try {
        final res = await client.from('likes').select().eq('post_id', postId);
        return List<Map<String, dynamic>>.from(res);
      } catch (e) {
        return [];
      }
    });
  }

  // --- OYLAMA İŞLEMLERİ ---
  Future<void> castVote(String postId, int voteType) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    final existingVote = await client
        .from('votes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', user.id)
        .maybeSingle();

    if (existingVote != null) {
      if (existingVote['vote_type'] == voteType) {
        await client.from('votes').delete().eq('id', existingVote['id']);
      } else {
        await client
            .from('votes')
            .update({'vote_type': voteType})
            .eq('id', existingVote['id']);
      }
    } else {
      await client.from('votes').insert({
        'post_id': postId,
        'user_id': user.id,
        'vote_type': voteType,
      });
    }
  }

  Stream<List<Map<String, dynamic>>> getVotesStream(String postId) {
    return client.from('profiles').stream(primaryKey: ['id']).asyncMap((
      _,
    ) async {
      try {
        final res = await client.from('votes').select().eq('post_id', postId);
        return List<Map<String, dynamic>>.from(res);
      } catch (e) {
        return [];
      }
    });
  }

  // --- YORUM İŞLEMLERİ ---
  Future<void> createComment(String postId, String content) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Yorum yapmak için giriş yapmalısın.');

    final profile = await client
        .from('profiles')
        .select('is_shadow_mode')
        .eq('id', user.id)
        .maybeSingle();
    final bool isGlobalShadowActive = profile?['is_shadow_mode'] ?? false;

    await client.from('comments').insert({
      'post_id': postId,
      'user_id': user.id,
      'content': content,
      'is_anonymous': isGlobalShadowActive,
    });

    final postData = await client
        .from('posts')
        .select('user_id')
        .eq('id', postId)
        .maybeSingle();
    if (postData != null && postData['user_id'] != user.id) {
      await sendNotification(
        targetUserId: postData['user_id'] as String,
        type: 'comment',
        content: 'Gönderine bir yorum yaptı.',
      );
    }
  }

  Stream<List<Map<String, dynamic>>> getCommentsStream(String postId) {
    return client.from('posts').stream(primaryKey: ['id']).asyncMap((_) async {
      try {
        final res = await client
            .from('comments')
            .select()
            .eq('post_id', postId)
            .order('created_at', ascending: true);
        return List<Map<String, dynamic>>.from(res);
      } catch (e) {
        return [];
      }
    });
  }

  // --- ÖZEL MESAJLAŞMA (TİTANYUM ZIRHI - GERİYE DÖNÜK UYUMLU) ---

  // DİKKAT: otherUserId artık zorunlu (ilk parametre). iAmAnonymous ve isOtherAnonymous varsayılan olarak false (eski ekranlar çökmesin diye)
  Future<String> getOrCreateChat(
    String otherUserId, {
    bool iAmAnonymous = false,
    bool isOtherAnonymous = false,
  }) async {
    final myId = client.auth.currentUser!.id;

    final List<dynamic> response = await client
        .from('chats')
        .select()
        .or('user1_id.eq.$myId,user2_id.eq.$myId');

    final chats = List<Map<String, dynamic>>.from(response);

    Map<String, dynamic>? existingChat;

    for (var chat in chats) {
      final isUser1Me = chat['user1_id'] == myId;
      final isUser2Other =
          (isUser1Me ? chat['user2_id'] : chat['user1_id']) == otherUserId;

      if (isUser2Other) {
        final myAnonStateInChat = isUser1Me
            ? (chat['user1_is_anon'] ?? false)
            : (chat['user2_is_anon'] ?? false);
        final otherAnonStateInChat = isUser1Me
            ? (chat['user2_is_anon'] ?? false)
            : (chat['user1_is_anon'] ?? false);

        if (myAnonStateInChat == iAmAnonymous &&
            otherAnonStateInChat == isOtherAnonymous) {
          existingChat = chat;
          break;
        }
      }
    }

    if (existingChat != null) {
      return existingChat['id'];
    }

    final newChat = await client
        .from('chats')
        .insert({
          'user1_id': myId,
          'user2_id': otherUserId,
          'user1_is_anon': iAmAnonymous,
          'user2_is_anon': isOtherAnonymous,
        })
        .select()
        .single();

    return newChat['id'];
  }

  // DİKKAT: chatId ve content ilk parametreler. isAnonymous varsayılan olarak false.
  Future<void> sendMessage(
    String chatId,
    String content, {
    bool isAnonymous = false,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    final profile = await client
        .from('profiles')
        .select('is_shadow_mode')
        .eq('id', user.id)
        .maybeSingle();
    final bool isGlobalShadowActive = profile?['is_shadow_mode'] ?? false;
    final finalAnonymous = isGlobalShadowActive || isAnonymous;

    await client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'content': content,
      'is_anonymous': finalAnonymous,
      'is_read': false,
    });
  }

  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);
  }

  Stream<List<Map<String, dynamic>>> getInboxChatsStream() {
    final myId = client.auth.currentUser!.id;
    return client
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (chats) => chats
              .where(
                (chat) => chat['user1_id'] == myId || chat['user2_id'] == myId,
              )
              .toList(),
        );
  }

  Stream<int> getUnreadChatsCountStream() {
    final myId = client.auth.currentUser?.id;
    if (myId == null) return Stream.value(0);
    return client.from('messages').stream(primaryKey: ['id']).map((messages) {
      final unreadChatIds = messages
          .where((m) => m['sender_id'] != myId && m['is_read'] == false)
          .map((m) => m['chat_id'])
          .toSet();
      return unreadChatIds.length;
    });
  }

  Future<void> markMessagesAsRead(String chatId) async {
    final myId = client.auth.currentUser?.id;
    if (myId == null) return;
    await client
        .from('messages')
        .update({'is_read': true})
        .eq('chat_id', chatId)
        .neq('sender_id', myId);
  }

  // ==========================================
  // BİLDİRİM MERKEZİ (HABERCİ) İŞLEMLERİ
  // ==========================================
  Stream<int> getUnreadNotificationsCountStream() {
    final myId = client.auth.currentUser?.id;
    if (myId == null) return Stream.value(0);

    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .map(
          (notifications) => notifications
              .where((n) => n['user_id'] == myId && n['is_read'] == false)
              .length,
        );
  }

  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    final myId = client.auth.currentUser?.id;
    if (myId == null) return const Stream.empty();

    return client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (notifications) =>
              notifications.where((n) => n['user_id'] == myId).toList(),
        );
  }

  Future<void> markAllNotificationsAsRead() async {
    final myId = client.auth.currentUser?.id;
    if (myId == null) return;

    await client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', myId)
        .eq('is_read', false);
  }

  Future<void> sendNotification({
    required String targetUserId,
    required String type,
    required String content,
  }) async {
    final myId = client.auth.currentUser?.id;
    if (myId == null || myId == targetUserId) return;

    await client.from('notifications').insert({
      'user_id': targetUserId,
      'sender_id': myId,
      'type': type,
      'content': content,
      'is_read': false,
    });
  }

  // ==========================================
  // ENLER (TRENDLER) İŞLEMLERİ
  // ==========================================
  Future<List<Map<String, dynamic>>> getTrendingPosts(String filterType) async {
    DateTime now = DateTime.now();
    DateTime? fromDate;

    if (filterType == 'daily') {
      fromDate = now.subtract(const Duration(days: 1));
    } else if (filterType == 'weekly') {
      fromDate = now.subtract(const Duration(days: 7));
    } else if (filterType == 'monthly') {
      fromDate = now.subtract(const Duration(days: 30));
    }

    var query = client.from('trending_posts').select();
    if (fromDate != null) {
      query = query.gte('created_at', fromDate.toIso8601String());
    }

    final response = await query
        .order('like_count', ascending: false)
        .order('created_at', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(response);
  }

  // ==========================================
  // ETİKET (HASHTAG) İŞLEMLERİ
  // ==========================================
  Future<List<Map<String, dynamic>>> getTrendingHashtags() async {
    final response = await client.from('trending_hashtags').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Stream<List<Map<String, dynamic>>> getPostsByHashtagStream(String hashtag) {
    return client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (posts) => posts.where((p) {
            final content = (p['content'] ?? '').toString().toLowerCase();
            return content.contains('#${hashtag.toLowerCase()}');
          }).toList(),
        );
  }

  // ==========================================
  // TAKİP SİSTEMİ (FOLLOWERS)
  // ==========================================
  Future<void> toggleFollow(String targetUserId) async {
    final myId = client.auth.currentUser?.id;
    if (myId == null || myId == targetUserId) {
      return;
    }

    final existing = await client
        .from('followers')
        .select()
        .eq('follower_id', myId)
        .eq('following_id', targetUserId)
        .maybeSingle();

    if (existing != null) {
      await client
          .from('followers')
          .delete()
          .eq('follower_id', myId)
          .eq('following_id', targetUserId);
    } else {
      await client.from('followers').insert({
        'follower_id': myId,
        'following_id': targetUserId,
      });
      await sendNotification(
        targetUserId: targetUserId,
        type: 'follow',
        content: 'Seni takip etmeye başladı.',
      );
    }
  }

  Future<List<String>> getMyFollowingIds() async {
    final myId = client.auth.currentUser?.id;
    if (myId == null) return [];

    final response = await client
        .from('followers')
        .select('following_id')
        .eq('follower_id', myId);
    return response.map((e) => e['following_id'] as String).toList();
  }

  // ==========================================
  // GÜVENLİK VE MODERASYON (ŞİKAYET & ENGEL)
  // ==========================================
  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    final myId = client.auth.currentUser?.id;
    if (myId == null) return;

    await client.from('reports').insert({
      'post_id': postId,
      'reporter_id': myId,
      'reason': reason,
    });
  }

  Future<void> blockUser(String blockedUserId) async {
    final myId = client.auth.currentUser?.id;
    if (myId == null || myId == blockedUserId) return;

    await client.from('blocks').insert({
      'blocker_id': myId,
      'blocked_id': blockedUserId,
    });

    await client
        .from('followers')
        .delete()
        .eq('follower_id', myId)
        .eq('following_id', blockedUserId);
    await client
        .from('followers')
        .delete()
        .eq('follower_id', blockedUserId)
        .eq('following_id', myId);
  }

  Future<void> unblockUser(String blockedUserId) async {
    final myId = client.auth.currentUser?.id;
    if (myId == null) return;

    await client
        .from('blocks')
        .delete()
        .eq('blocker_id', myId)
        .eq('blocked_id', blockedUserId);
  }

  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final myId = client.auth.currentUser?.id;
    if (myId == null) return [];

    final response = await client
        .from('blocks')
        .select('blocked_id')
        .eq('blocker_id', myId);
    final blockedIds = response.map((e) => e['blocked_id'] as String).toList();

    if (blockedIds.isEmpty) return [];

    final profiles = await client
        .from('profiles')
        .select()
        .inFilter('id', blockedIds);
    return List<Map<String, dynamic>>.from(profiles);
  }

  Future<List<String>> getBlockListIds() async {
    final myId = client.auth.currentUser?.id;
    if (myId == null) return [];

    final myBlocks = await client
        .from('blocks')
        .select('blocked_id')
        .eq('blocker_id', myId);
    final whoBlockedMe = await client
        .from('blocks')
        .select('blocker_id')
        .eq('blocked_id', myId);

    final List<String> ids = [];
    for (var b in myBlocks) {
      ids.add(b['blocked_id'] as String);
    }
    for (var b in whoBlockedMe) {
      ids.add(b['blocker_id'] as String);
    }

    return ids;
  }
}
