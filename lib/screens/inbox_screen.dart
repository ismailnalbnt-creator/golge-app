import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'chat_room_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _supabaseService = SupabaseService();
  final _myId = Supabase.instance.client.auth.currentUser!.id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'MESAJLAR',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 1,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: Colors.white10, height: 1),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabaseService.getInboxChatsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            );
          }

          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white10,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Gelen kutun bomboş.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Birilerine selam vererek başla!',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              // Odadaki hangi kullanıcının ben, hangi kullanıcının karşı taraf olduğunu buluyoruz:
              final isUser1Me = chat['user1_id'] == _myId;
              final otherUserId = isUser1Me
                  ? chat['user2_id']
                  : chat['user1_id'];

              // Karşı tarafın o odadaki maske durumunu (anonim olup olmadığını) buluyoruz:
              final otherIsAnon = isUser1Me
                  ? (chat['user2_is_anon'] ?? false)
                  : (chat['user1_is_anon'] ?? false);

              return FutureBuilder<Map<String, dynamic>?>(
                future: _supabaseService.getProfileById(otherUserId),
                builder: (context, profileSnap) {
                  final profile = profileSnap.data;

                  // Eğer karşı taraf odada anonimse "Gölge Kullanıcı" yazsın, değilse adını soyadını yazsın
                  final fullName = otherIsAnon
                      ? 'Gölge Kullanıcı'
                      : "${profile?['first_name'] ?? ''} ${profile?['last_name'] ?? ''}";
                  final username = otherIsAnon
                      ? ''
                      : "@${profile?['username'] ?? ''}";

                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabaseService.getMessagesStream(chat['id']),
                    builder: (context, messageSnap) {
                      final messages = messageSnap.data ?? [];
                      final lastMessage = messages.isNotEmpty
                          ? messages.last['content']
                          : 'Henüz mesaj yok';

                      // O odadaki bana ait olan ve henüz okumadığım mesajların sayısı
                      final unreadCount = messages
                          .where(
                            (m) =>
                                m['sender_id'] != _myId &&
                                m['is_read'] == false,
                          )
                          .length;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: otherIsAnon
                              ? Colors.black
                              : const Color(0xFF1A1A1A),
                          child: Icon(
                            otherIsAnon ? Icons.masks : Icons.person,
                            color: otherIsAnon
                                ? Colors.white38
                                : Colors.tealAccent,
                            size: 24,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              fullName.trim().isEmpty ? "İsimsiz" : fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (!otherIsAnon && username.length > 1)
                              Text(
                                username,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unreadCount > 0
                                  ? Colors.white
                                  : Colors.white54,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        trailing: unreadCount > 0
                            ? Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.deepPurpleAccent,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.chevron_right,
                                color: Colors.white10,
                              ),
                        onTap: () {
                          // --- HATA BURADA ÇÖZÜLDÜ: SADECE chatId ve otherUserId GİDİYOR! ---
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatRoomScreen(
                                chatId: chat['id'],
                                otherUserId: otherUserId,
                              ),
                            ),
                          );
                        },
                      );
                    },
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
