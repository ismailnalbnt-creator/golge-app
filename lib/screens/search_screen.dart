import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'public_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _client = Supabase.instance.client;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Adım: İsme, soyisme veya kullanıcı adına göre veritabanında arama yap
      final response = await _client
          .from('profiles')
          .select()
          .or(
            'username.ilike.%${query.trim()}%,first_name.ilike.%${query.trim()}%,last_name.ilike.%${query.trim()}%',
          );

      // 2. Adım: TİTANYUM ZIRHI KORUMASI
      // Gölge modu aktif olan kullanıcıları arama sonuçlarından gizle
      final filteredResults = (response as List<dynamic>)
          .where((profile) {
            final isShadow = profile['is_shadow_mode'] == true;
            return !isShadow;
          })
          .map((e) => e as Map<String, dynamic>)
          .toList();

      if (mounted) {
        setState(() {
          _searchResults = filteredResults;
        });
      }
    } catch (e) {
      debugPrint('Arama hatası: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'İsim veya kullanıcı adı ara...',
            hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
            border: InputBorder.none,
          ),
          onChanged: _performSearch,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Colors.white10, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            )
          : _searchResults.isEmpty && _searchController.text.trim().isNotEmpty
          ? const Center(
              child: Text(
                'Gölgeler arasında böyle biri bulunamadı.',
                style: TextStyle(color: Colors.white38),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final user = _searchResults[index];
                final fullName =
                    "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}";
                final username = "@${user['username'] ?? ''}";

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF1A1A1A),
                    child: Icon(
                      Icons.person,
                      color: Colors.tealAccent,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    fullName.trim().isEmpty ? "İsimsiz" : fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    username,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white10,
                  ),
                  onTap: () {
                    // Tıklanan kişinin açık profiline yönlendir
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PublicProfileScreen(userId: user['id']),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
