import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'sirdas_screen.dart';
import 'radar_screen.dart';
import 'inbox_screen.dart';
import 'notifications_screen.dart';
import 'trending_screen.dart';
import 'hashtags_screen.dart'; // Etiketler ekranı bağlandı
import '../services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Varsayılan olarak 1 yani "Akış" ekranı açık açılacak.
  int _currentIndex = 1;
  final _supabaseService = SupabaseService();

  final List<Widget> _screens = [
    const RadarScreen(),
    const FeedScreen(),
    const SirdasScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),

      // --- SOL ÇEKMECE MENÜ (DRAWER) ---
      drawer: Drawer(
        backgroundColor: const Color(0xFF121212),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'G Ö L G E',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Gizli Dünyana Hoş Geldin',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.tag, color: Colors.deepPurpleAccent),
              title: const Text(
                'Gündem (Etiketler)',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context); // Önce menüyü kapat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HashtagsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'G Ö L G E',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 6,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        // DİKKAT: Sol taraftaki menü (Drawer) ikonunun otomatik gelmesi için automaticallyImplyLeading kaldırıldı.

        // --- SAĞ ÜST KÖŞEDEKİ EYLEM BUTONLARI ---
        actions: [
          // 1. ENLER / TRENDLER BUTONU (KUPA İKONU)
          IconButton(
            icon: const Icon(
              Icons.emoji_events_outlined,
              color: Colors.amber,
              size: 26,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrendingScreen()),
              );
            },
          ),
          const SizedBox(width: 4),

          // 2. ZİL / BİLDİRİMLER İKONU (MOR BALONLU)
          StreamBuilder<int>(
            stream: _supabaseService.getUnreadNotificationsCountStream(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return Badge(
                label: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                isLabelVisible: unreadCount > 0,
                backgroundColor: Colors.deepPurpleAccent,
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 4),

          // 3. DM / GELEN KUTUSU İKONU (KIRMIZI BALONLU)
          StreamBuilder<int>(
            stream: _supabaseService.getUnreadChatsCountStream(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return Badge(
                label: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                isLabelVisible: unreadCount > 0,
                backgroundColor: Colors.redAccent,
                child: IconButton(
                  icon: const Icon(
                    Icons.near_me_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InboxScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.black,
          selectedItemColor: Colors.deepPurpleAccent,
          unselectedItemColor: Colors.white54,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          iconSize: 22,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.radar),
              ),
              label: 'Çevrendekiler',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.dynamic_feed),
              ),
              label: 'Akış',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.gavel),
              ),
              label: 'Sırdaş',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person),
              ),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
