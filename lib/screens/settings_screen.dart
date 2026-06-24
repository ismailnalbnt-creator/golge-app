import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'block_list_screen.dart';
// import 'login_screen.dart'; // Çıkış yaptıktan sonra yönlendirmek için kendi giriş sayfanı buraya ekle

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _client = Supabase.instance.client;

  bool _isShadowMode = false;
  bool _isRadarVisible = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Veritabanından kullanıcının mevcut ayarlarını çekiyoruz
  Future<void> _loadSettings() async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return;

    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', myId)
          .maybeSingle();
      if (profile != null) {
        setState(() {
          // Eğer veritabanında bu sütunlar null ise varsayılan değerleri atıyoruz
          _isShadowMode = profile['is_shadow_mode'] ?? false;
          _isRadarVisible = profile['is_radar_visible'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Ayarlar yüklenirken hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Şalterlerle oynandığında veritabanını anında güncelleyen fonksiyon
  Future<void> _updateSetting(String key, bool value) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return;

    try {
      await _client.from('profiles').update({key: value}).eq('id', myId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ayar güncellenirken hata oluştu: $e')),
        );
      }
    }
  }

  // Çıkış Yapma İşlemi
  Future<void> _signOut() async {
    await _client.auth.signOut();
    if (mounted) {
      // Çıkış yapınca tüm sayfaları kapatıp Giriş ekranına fırlatıyoruz
      // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);

      // *Geçici olarak sadece bir önceki ekrana dönmesi için (Login ekranını bağlayınca üstteki kodu açarsın):
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'AYARLAR',
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
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // ==========================================
                // 1. BÖLÜM: GİZLİLİK AYARLARI
                // ==========================================
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'GİZLİLİK',
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Container(
                  color: const Color(0xFF121212),
                  child: Column(
                    children: [
                      // KÜRESEL GÖLGE MODU
                      SwitchListTile(
                        activeThumbColor: Colors.deepPurpleAccent,
                        inactiveThumbColor: Colors.white54,
                        inactiveTrackColor: Colors.white10,
                        title: const Text(
                          'Küresel Gölge Modu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'Akışta ve yorumlarda kimliğin tamamen gizlenir.',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        secondary: const Icon(
                          Icons.masks,
                          color: Colors.white54,
                        ),
                        value: _isShadowMode,
                        onChanged: (value) {
                          setState(() => _isShadowMode = value);
                          _updateSetting('is_shadow_mode', value);
                        },
                      ),
                      const Divider(color: Colors.white10, height: 1),

                      // RADAR GÖRÜNÜRLÜĞÜ
                      SwitchListTile(
                        activeThumbColor: Colors.deepPurpleAccent,
                        inactiveThumbColor: Colors.white54,
                        inactiveTrackColor: Colors.white10,
                        title: const Text(
                          'Radar Görünürlüğü',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text(
                          'Yakınındaki diğer açık profiller seni görebilir.',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        secondary: const Icon(
                          Icons.radar,
                          color: Colors.white54,
                        ),
                        value: _isRadarVisible,
                        onChanged: (value) {
                          setState(() => _isRadarVisible = value);
                          _updateSetting(
                            'is_radar_visible',
                            value,
                          ); // *Not: Veritabanında is_radar_visible sütunu olmalı
                        },
                      ),
                      const Divider(color: Colors.white10, height: 1),

                      // ENGELLENEN KULLANICILAR MENÜSÜ
                      ListTile(
                        leading: const Icon(
                          Icons.block,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                        title: const Text(
                          'Engellenen Kullanıcılar',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.white38,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BlockListScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ==========================================
                // 2. BÖLÜM: HESAP AYARLARI
                // ==========================================
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'HESAP',
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Container(
                  color: const Color(0xFF121212),
                  child: Column(
                    children: [
                      // ÇIKIŞ YAP BUTONU
                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                        title: const Text(
                          'Çıkış Yap',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          // Kullanıcıya Emin Misin sorusu soralım
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1A1A1A),
                              title: const Text(
                                'Çıkış Yap',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              content: const Text(
                                'Hesabından çıkış yapmak istediğine emin misin?',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'İptal',
                                    style: TextStyle(color: Colors.white38),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Diyaloğu kapat
                                    _signOut(); // Çıkış yap
                                  },
                                  child: const Text(
                                    'Çıkış Yap',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // UYGULAMA VERSİYON BİLGİSİ
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'G Ö L G E',
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'v1.0.0',
                        style: TextStyle(color: Colors.white24, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
