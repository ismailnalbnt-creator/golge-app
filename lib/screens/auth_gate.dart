import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'home_screen.dart'; // İŞTE EKSİK OLAN HAYATİ BAĞLANTI BURASI

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0A0A),
            body: Center(
              child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
            ),
          );
        }

        final session = snapshot.data?.session;

        // Kullanıcının aktif bir oturumu varsa doğrudan yeni Ana Ekrana yolla
        if (session != null) {
          return const HomeScreen();
        }

        // Oturum yoksa veya çıkış yapıldıysa Giriş/Kayıt ekranına yolla
        return const AuthScreen();
      },
    );
  }
}
