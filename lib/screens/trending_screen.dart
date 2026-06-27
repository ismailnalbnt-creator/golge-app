import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'public_profile_screen.dart'; // PROFİLE YÖNLENDİRME İÇİN EKLENDİ

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});

  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  final _supabaseService = SupabaseService();

  // Varsayılan filtre: Günlük
  String _selectedFilter = 'daily';

  final Map<String, String> _filters = {
    'Günlük': 'daily',
    'Haftalık': 'weekly',
    'Aylık': 'monthly',
    'Tüm Zamanlar': 'all',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 22),
            SizedBox(width: 8),
            Text(
              'ENLER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- FİLTRELEME BUTONLARI (Yatay Kaydırılabilir) ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white10, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _filters.entries.map((entry) {
                  final isSelected = _selectedFilter == entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(entry.key),
                      selected: isSelected,
                      // ignore: deprecated_member_use
                      selectedColor: Colors.amber.withOpacity(0.2),
                      backgroundColor: const Color(0xFF1A1A1A),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.amber : Colors.white54,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? Colors.amber : Colors.white10,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFilter = entry.value;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // --- GÖNDERİ LİSTESİ ---
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              // Filtre her değiştiğinde bu Future baştan çalışır
              future: _supabaseService.getTrendingPosts(_selectedFilter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.amber),
                  );
                }

                final posts = snapshot.data;
                if (posts == null || posts.isEmpty) {
                  return const Center(
                    child: Text(
                      'Bu zaman diliminde henüz popüler bir gönderi yok.',
                      style: TextStyle(
                        color: Colors.white38,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final isAnonymous = post['is_anonymous'] ?? false;
                    final postUserId =
                        post['user_id']; // Yönlendirme için ID çekildi

                    final fullName = isAnonymous
                        ? 'Gölge Kullanıcı'
                        : "${post['first_name']} ${post['last_name']}";
                    final username = isAnonymous ? '' : "@${post['username']}";
                    final likeCount = post['like_count'] ?? 0;

                    return Card(
                      color: const Color(0xFF121212),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.white10, width: 1),
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
                                // --- TIKLANABİLİR PROFİL ALANI ---
                                GestureDetector(
                                  onTap: () {
                                    if (!isAnonymous && postUserId != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PublicProfileScreen(
                                                userId: postUserId,
                                              ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: isAnonymous
                                            ? Colors.black
                                            : const Color(0xFF1A1A1A),
                                        child: Icon(
                                          isAnonymous
                                              ? Icons.masks
                                              : Icons.person,
                                          color: isAnonymous
                                              ? Colors.white38
                                              : Colors.tealAccent,
                                          size: 16,
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
                                          if (!isAnonymous)
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
                                ),
                                // 1., 2. ve 3. olanlara özel taç / madalya ikonu
                                if (index == 0)
                                  const Icon(
                                    Icons.emoji_events,
                                    color: Colors.amber,
                                    size: 20,
                                  )
                                else if (index == 1)
                                  const Icon(
                                    Icons.emoji_events,
                                    color: Color(0xFFC0C0C0),
                                    size: 20,
                                  ) // Gümüş
                                else if (index == 2)
                                  const Icon(
                                    Icons.emoji_events,
                                    color: Color(0xFFCD7F32),
                                    size: 20,
                                  ) // Bronz
                                else
                                  Text(
                                    '#${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  color: Colors.redAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$likeCount Beğeni',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}
