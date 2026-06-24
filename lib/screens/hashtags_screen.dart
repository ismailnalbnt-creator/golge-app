import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'hashtag_detail_screen.dart';

class HashtagsScreen extends StatefulWidget {
  const HashtagsScreen({super.key});

  @override
  State<HashtagsScreen> createState() => _HashtagsScreenState();
}

class _HashtagsScreenState extends State<HashtagsScreen> {
  final _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'GÜNDEM',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 1,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _supabaseService.getTrendingHashtags(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            );
          }

          final tags = snapshot.data;
          if (tags == null || tags.isEmpty) {
            return const Center(
              child: Text(
                'Henüz gündemde bir etiket yok.',
                style: TextStyle(color: Colors.white38),
              ),
            );
          }

          return ListView.builder(
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              final hashtagName = tag['hashtag'] ?? '';
              final count = tag['usage_count'] ?? 0;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                leading: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                title: Text(
                  '#$hashtagName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  '$count Paylaşım',
                  style: const TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontSize: 12,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white10,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HashtagDetailScreen(hashtag: hashtagName),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
