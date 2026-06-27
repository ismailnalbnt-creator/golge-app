import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'block_list_screen.dart';

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

  // Profil düzenleme bilgileri için saklanan eyalet (state) değişkenleri
  String _firstName = '';
  String _lastName = '';
  String _username = '';
  String _bio = '';
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Veritabanından kullanıcının tüm mevcut ayarlarını ve kişisel bilgilerini çekiyoruz
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
          _isShadowMode = profile['is_shadow_mode'] ?? false;
          _isRadarVisible = profile['is_radar_visible'] ?? true;
          _firstName = profile['first_name'] ?? '';
          _lastName = profile['last_name'] ?? '';
          _username = profile['username'] ?? '';
          _bio = profile['bio'] ?? '';
          _birthDate = profile['birth_date'] != null
              ? DateTime.parse(profile['birth_date'])
              : null;
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
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // ==========================================
  // YENİ EKLENEN: KİŞİSEL BİLGİLERİ DÜZENLEME PANELİ
  // ==========================================
  void _showEditProfileDialog() {
    final firstNameController = TextEditingController(text: _firstName);
    final lastNameController = TextEditingController(text: _lastName);
    final usernameController = TextEditingController(text: _username);
    final bioController = TextEditingController(text: _bio);
    DateTime? tempBirthDate = _birthDate;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF121212),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Profil Bilgilerini Düzenle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: firstNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Ad',
                        labelStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white10),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.deepPurpleAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: lastNameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Soyad',
                        labelStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white10),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.deepPurpleAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Kullanıcı Adı',
                        labelStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white10),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.deepPurpleAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: bioController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Biyografi',
                        labelStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white10),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.deepPurpleAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Doğum Tarihi',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      subtitle: Text(
                        tempBirthDate == null
                            ? 'Seçilmedi'
                            : '${tempBirthDate!.day}/${tempBirthDate!.month}/${tempBirthDate!.year}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.calendar_today,
                        color: Colors.white54,
                        size: 18,
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempBirthDate ?? DateTime(2000),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Colors.deepPurpleAccent,
                                  onPrimary: Colors.white,
                                  surface: Color(0xFF1E1E1E),
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setDialogState(() => tempBirthDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text(
                    'İptal',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (usernameController.text.trim().isEmpty) return;
                          setDialogState(() => isSaving = true);
                          try {
                            final myId = _client.auth.currentUser!.id;
                            await _client
                                .from('profiles')
                                .update({
                                  'first_name': firstNameController.text.trim(),
                                  'last_name': lastNameController.text.trim(),
                                  'username': usernameController.text.trim(),
                                  'bio': bioController.text.trim(),
                                  'birth_date': tempBirthDate
                                      ?.toIso8601String(),
                                })
                                .eq('id', myId);

                            await _loadSettings(); // Ayarları ve yerel state'i yenile
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Hata: $e')),
                              );
                            }
                          } finally {
                            setDialogState(() => isSaving = false);
                          }
                        },
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
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
                          _updateSetting('is_radar_visible', value);
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
                      // PROFİLİ DÜZENLE SEÇENEĞİ (MENÜ OLARAK EKLENDİ)
                      ListTile(
                        leading: const Icon(
                          Icons.person_outline,
                          color: Colors.white54,
                          size: 22,
                        ),
                        title: const Text(
                          'Profil Bilgilerini Düzenle',
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.white38,
                        ),
                        onTap: _showEditProfileDialog,
                      ),
                      const Divider(color: Colors.white10, height: 1),

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
                                    Navigator.pop(context);
                                    _signOut();
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
