import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase bağlantımızı başlatıyoruz
  await Supabase.initialize(
    url:
        'https://igkjaftcgzqqnzlhqqbo.supabase.co', // Supabase Project URL'ni buraya yapıştır
    // ignore: deprecated_member_use
    anonKey:
        'sb_publishable_79gAijXiC62KlGE-piA3Uw_h9ZraUJr', // Supabase Anon Key'ini buraya yapıştır
  );

  runApp(const GolgeApp());
}

class GolgeApp extends StatelessWidget {
  const GolgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gölge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // Uygulama açıldığında artık o yazıyı değil, doğrudan Giriş Ekranımızı başlatıyoruz:
      home: const AuthGate(),
    );
  }
}
