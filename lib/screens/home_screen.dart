import 'package:flutter/material.dart';
import 'feed_screen.dart';
import 'profile_screen.dart';
import 'sirdas_screen.dart';
import 'radar_screen.dart';
import 'inbox_screen.dart';
import '../services/supabase_service.dart'; // Servisi bağladık

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1;
  final _supabaseService = SupabaseService(); // Servis nesnemizi tanımladık

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
        automaticallyImplyLeading: false,
        actions: [
          // GÜNCELLENDİ: Anlık Okunmamış Mesaj Sayıcılı DM İkonu
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
                isLabelVisible:
                    unreadCount >
                    0, // Okunmamış mesaj varsa balonu göster, yoksa gizle
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
