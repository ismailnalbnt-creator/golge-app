import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final client = Supabase.instance.client;

  // --- KİMLİK DOĞRULAMA İŞLEMLERİ ---
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

  // --- GÖNDERİ (AKIŞ) İŞLEMLERİ ---
  Future<void> createPost(String content) async {
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Gönderi paylaşmak için giriş yapmalısın.');
    }

    await client.from('posts').insert({'user_id': user.id, 'content': content});
  }

  Future<void> deletePost(String postId) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Silme işlemi için giriş yapmalısın.');
    await client.from('posts').delete().eq('id', postId).eq('user_id', user.id);
  }

  Stream<List<Map<String, dynamic>>> getPostsStream() {
    return client
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> getMyPostsStream() {
    final user = client.auth.currentUser;
    if (user == null) return const Stream.empty();

    return client
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
  }

  // --- MAHKEME (OYLAMA) İŞLEMLERİ ---
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
    return client
        .from('votes')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId);
  }

  // --- YENİ EKLENEN: YORUM (SAVUNMA) İŞLEMLERİ ---

  // 1. Yeni yorum gönderme
  Future<void> createComment(String postId, String content) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Yorum yapmak için giriş yapmalısın.');

    await client.from('comments').insert({
      'post_id': postId,
      'user_id': user.id,
      'content': content,
    });
  }

  // 2. Bir gönderiye ait yorumları anlık canlı çekme
  Stream<List<Map<String, dynamic>>> getCommentsStream(String postId) {
    return client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order(
          'created_at',
          ascending: true,
        ); // Eski yorumlar üstte, yeniler altta
  }
}
