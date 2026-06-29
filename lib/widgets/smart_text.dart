import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/hashtag_detail_screen.dart';
import '../screens/public_profile_screen.dart';

class SmartText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const SmartText({super.key, required this.text, this.style});

  // Etikete (#) tıklandığında çalışacak köprü
  void _handleHashtagTap(BuildContext context, String hashtag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HashtagDetailScreen(hashtag: hashtag.replaceAll('#', '')),
      ),
    );
  }

  // Kullanıcıya (@) tıklandığında çalışacak köprü
  void _handleMentionTap(BuildContext context, String mention) async {
    final username = mention.replaceAll('@', '');
    
    // Veritabanında ararken kısa bir yükleme ekranı göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
    );
    
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();
          
      if (context.mounted) Navigator.pop(context); // Yüklemeyi kapat
      
      if (response != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PublicProfileScreen(userId: response['id']),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı bulunamadı veya gölgelere karışmış.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Metnin içindeki # ve @ işaretli kelimeleri yakalayan radar
    final RegExp exp = RegExp(r'(#\w+|@\w+)');
    final Iterable<Match> matches = exp.allMatches(text);
    
    // Eğer metinde hiç etiket yoksa normal metin döndür
    if (matches.isEmpty) {
      return Text(text, style: style);
    }

    List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    for (Match match in matches) {
      final String matchedText = match.group(0)!;
      final int matchStart = match.start;
      final int matchEnd = match.end;

      // Eşleşmeden önceki normal (düz) metin
      if (matchStart > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, matchStart), style: style));
      }

      // Eşleşen sihirli etiket (#) veya mention (@)
      final isHashtag = matchedText.startsWith('#');
      spans.add(
        TextSpan(
          text: matchedText,
          style: style?.copyWith(
            color: isHashtag ? Colors.deepPurpleAccent : Colors.tealAccent,
            fontWeight: FontWeight.bold,
          ) ?? TextStyle(
            color: isHashtag ? Colors.deepPurpleAccent : Colors.tealAccent,
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (isHashtag) {
                _handleHashtagTap(context, matchedText);
              } else {
                _handleMentionTap(context, matchedText);
              }
            },
        ),
      );

      lastMatchEnd = matchEnd;
    }

    // Son eşleşmeden sonraki kalan düz metin
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: style));
    }

    return RichText(text: TextSpan(children: spans));
  }
}