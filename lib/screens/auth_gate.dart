import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Supabase'in anlık oturum durumunu (giriş yaptı mı, çıktı mı) dinleyen bir yapı kuruyoruz
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Sistem hala veritabanına soruyorsa (milisaniyelik yüklenme anı) siyah bir bekleme ekranı göster
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        // Kullanıcının geçerli bir oturumu (session) var mı diye bakıyoruz
        final session = snapshot.hasData ? snapshot.data!.session : null;

        // Eğer oturum varsa doğrudan içeri al, yoksa kapıya (Kayıt/Giriş) yönlendir
        if (session != null) {
          return const HomeScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}
