import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class BlockListScreen extends StatefulWidget {
  const BlockListScreen({super.key});

  @override
  State<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockListScreenState extends State<BlockListScreen> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _supabaseService.getBlockedUsers();
      setState(() {
        _blockedUsers = users;
      });
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'ENGELLEDİĞİM KİŞİLER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            )
          : _blockedUsers.isEmpty
          ? const Center(
              child: Text(
                'Hiç kimseyi engellemedin.',
                style: TextStyle(color: Colors.white38),
              ),
            )
          : ListView.builder(
              itemCount: _blockedUsers.length,
              itemBuilder: (context, index) {
                final user = _blockedUsers[index];
                final fullName =
                    "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}";
                final username = "@${user['username'] ?? ''}";

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF1A1A1A),
                    child: Icon(Icons.person, color: Colors.white38),
                  ),
                  title: Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    username,
                    style: const TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 13,
                    ),
                  ),
                  trailing: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text(
                      'Engeli Kaldır',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      await _supabaseService.unblockUser(user['id']);
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Engel kaldırıldı.'),
                          backgroundColor: Colors.teal,
                        ),
                      );
                      _loadBlockedUsers(); // Listeyi anında yenile
                    },
                  ),
                );
              },
            ),
    );
  }
}
