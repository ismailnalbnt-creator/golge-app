import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'chat_room_screen.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService();
    final myId = Supabase.instance.client.auth.currentUser!.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        title: const Text(
          'Mesaj Kutusu',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabaseService.getInboxChatsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blueGrey),
            );
          }

          final chats = snapshot.data;
          if (chats == null || chats.isEmpty) {
            return const Center(
              child: Text(
                'Henüz kimseyle sohbetin yok.',
                style: TextStyle(
                  color: Colors.black38,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              // Odaya bakan kişinin BEN olduğumu bildiğim için, karşı tarafın ID'sini buluyorum:
              final otherUserId = chat['user1_id'] == myId
                  ? chat['user2_id']
                  : chat['user1_id'];

              return FutureBuilder<Map<String, dynamic>?>(
                future: supabaseService.getProfileById(otherUserId),
                builder: (context, profileSnap) {
                  if (!profileSnap.hasData) return const SizedBox();

                  final profile = profileSnap.data!;
                  final fullName =
                      "${profile['first_name']} ${profile['last_name']}";

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFECEFF1),
                        child: Icon(Icons.person, color: Colors.blueGrey),
                      ),
                      title: Text(
                        fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: const Text(
                        'Sohbete girmek için dokun...',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                      trailing: const Icon(
                        Icons.near_me_outlined,
                        color: Colors.black26,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomScreen(
                              chatId: chat['id'],
                              otherUserName: fullName,
                            ),
                          ),
                        );
                      },
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
