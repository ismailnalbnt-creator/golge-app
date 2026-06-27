// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart'; // DİKKAT: Uygulamanın ana ekranının adı farklıysa (örn: MainScreen) burayı değiştir!

// ==========================================
// KÜRESEL GÖLGE MODU ŞALTERİ
// ==========================================
final ValueNotifier<bool> globalShadowMode = ValueNotifier<bool>(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚨 KENDİ BİLGİLERİNİ BURAYA YAPIŞTIRMAYI UNUTMA! 🚨
  await Supabase.initialize(
    url: 'https://igkjaftcgzqqnzlhqqbo.supabase.co',
    anonKey: 'sb_publishable_79gAijXiC62KlGE-piA3Uw_h9ZraUJr',
  );

  runApp(const GolgeApp());
}

class GolgeApp extends StatelessWidget {
  const GolgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: globalShadowMode,
      builder: (context, isShadowActive, child) {
        return MaterialApp(
          title: 'Gölge',
          debugShowCheckedModeBanner: false,

          // --- GÜNDÜZ MODU (AÇIK KİMLİK) TEMASI ---
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              elevation: 1,
            ),
            colorScheme: const ColorScheme.light(
              primary: Colors.deepPurpleAccent,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            cardColor: Colors.white,
            dividerColor: Colors.black12,
          ),

          // --- GECE MODU (GÖLGE / ANONİM) TEMASI ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0A0A0A),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              elevation: 1,
            ),
            colorScheme: const ColorScheme.dark(
              primary: Colors.tealAccent,
              surface: Color(0xFF121212),
              onSurface: Colors.white,
            ),
            cardColor: const Color(0xFF121212),
            dividerColor: Colors.white10,
          ),

          themeMode: isShadowActive ? ThemeMode.dark : ThemeMode.light,

          // --- ZEKİ YÖNLENDİRME (DİNLEYİCİ) ---
          // Kullanıcının giriş yapıp yapmadığını anlık olarak takip eder
          home: StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                );
              }

              final session = snapshot.data?.session;
              if (session != null) {
                return const HomeScreen(); // Giriş başarılıysa açılacak sayfa (Adı farklıysa düzelt)
              } else {
                return const AuthScreen(); // Giriş yapılmadıysa açılacak sayfa
              }
            },
          ),
        );
      },
    );
  }
}
