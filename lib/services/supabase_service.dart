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

  // --- GÖNDERİ İŞLEMLERİ (AKIŞ VE SIRDAŞ) ---
  Future<void> createPost(
    String content, {
    bool isAnonymous = false,
    String postType = 'feed',
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Giriş yapmalısın.');

    await client.from('posts').insert({
      'user_id': user.id,
      'content': content,
      'is_anonymous': isAnonymous,
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
    await client.from('comments').insert({
      'post_id': postId,
      'user_id': user.id,
      'content': content,
    });
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

  // --- ÖZEL MESAJLAŞMA (CHAT) İŞLEMLERİ ---
  Future<String> getOrCreateChat(String otherUserId) async {
    final myId = client.auth.currentUser!.id;

    final List<dynamic> response = await client
        .from('chats')
        .select()
        .or('user1_id.eq.$myId,user2_id.eq.$myId');

    final chats = List<Map<String, dynamic>>.from(response);

    Map<String, dynamic>? existingChat;
    for (var chat in chats) {
      if ((chat['user1_id'] == myId && chat['user2_id'] == otherUserId) ||
          (chat['user1_id'] == otherUserId && chat['user2_id'] == myId)) {
        existingChat = chat;
        break;
      }
    }

    if (existingChat != null) {
      return existingChat['id'];
    }

    final newChat = await client
        .from('chats')
        .insert({'user1_id': myId, 'user2_id': otherUserId})
        .select()
        .single();

    return newChat['id'];
  }

  Future<void> sendMessage(String chatId, String content) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    await client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'content': content,
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
}
