import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'post_detail_screen.dart'; // Yeni Gönderi Detay Sayfası Bağlandı
import 'public_profile_screen.dart'; // Kişi Profili Bağlandı

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığı salise tüm bildirimleri "okundu" olarak işaretle ki zil ikonundaki kırmızı sayı sıfırlansın
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _supabaseService.markAllNotificationsAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'BİLDİRİMLER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabaseService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            );
          }

          final notifications = snapshot.data;
          if (notifications == null || notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    color: Colors.white10,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Henüz bir bildirim yok.',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isRead = notification['is_read'] ?? true;
              final type = notification['type'] ?? 'info';

              // Veritabanındaki yönlendirme anahtarları çekiliyor
              final postId = notification['post_id'];
              final senderId =
                  notification['sender_id'] ?? notification['actor_id'];

              // Bildirim tipine göre ikon ve renk belirliyoruz
              IconData iconData;
              Color iconColor;
              switch (type) {
                case 'like':
                  iconData = Icons.favorite;
                  iconColor = Colors.redAccent;
                  break;
                case 'comment':
                  iconData = Icons.chat_bubble;
                  iconColor = Colors.tealAccent;
                  break;
                case 'vote':
                  iconData = Icons.gavel;
                  iconColor = Colors.deepPurpleAccent;
                  break;
                default:
                  iconData = Icons.notifications;
                  iconColor = Colors.white54;
              }

              return Container(
                decoration: BoxDecoration(
                  color: isRead
                      ? Colors.transparent
                      : const Color(
                          0xFF1A1A1A,
                        ), // Okunmamışsa arka planı hafif aydınlık yap
                  border: const Border(
                    bottom: BorderSide(color: Colors.white10),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF121212),
                    child: Icon(iconData, color: iconColor, size: 20),
                  ),
                  title: Text(
                    notification['content'] ?? '',
                    style: TextStyle(
                      color: isRead ? Colors.white70 : Colors.white,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  trailing: isRead
                      ? null
                      : const CircleAvatar(
                          radius: 4,
                          backgroundColor: Colors.deepPurpleAccent,
                        ), // Okunmamışsa küçük mor nokta koy
                  // --- TIKLANABİLİR YÖNLENDİRME KÖPRÜSÜ (YENİ EKLENDİ) ---
                  onTap: () {
                    if (postId != null) {
                      // 1. Durum: Bildirim bir gönderiyle ilgiliyse (beğeni, yorum vs.) Gönderi Detayına fırlat
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PostDetailScreen(postId: postId),
                        ),
                      );
                    } else if (senderId != null) {
                      // 2. Durum: Sadece bir kullanıcıyla ilgiliyse (örn: yeni takipçi) Profiline fırlat
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PublicProfileScreen(userId: senderId),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
