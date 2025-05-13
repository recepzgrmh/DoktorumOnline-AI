// lib/services/openai_service.dart

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY']!;
  final Uri _endpoint = Uri.parse('https://api.openai.com/v1/chat/completions');

  /// 1. Adım: Kullanıcı verilerindeki eksik/ belirsiz noktaları
  /// madde madde sorulara dönüştürür.
  Future<List<String>> getFollowUpQuestions(Map<String, String> inputs) async {
    final prompt =
        StringBuffer()
          ..writeln("Kullanıcı bilgileri:")
          ..writeln("- Boy: ${inputs['Boy']}")
          ..writeln("- Yaş: ${inputs['Yaş']}")
          ..writeln("- Kilo: ${inputs['Kilo']}")
          ..writeln("- Şikayet: ${inputs['Şikayet']}")
          ..writeln("- Şikayet Süresi: ${inputs['Şikayet Süresi']}")
          ..writeln("- Mevcut İlaçlar: ${inputs['Mevcut İlaçlar']}")
          ..writeln("")
          ..writeln(
            "Lütfen kullanıcının sağladığı tüm hasta bilgilerini dikkatle incele ve aşağıdaki adımları takip et:",
          )
          ..writeln("")
          ..writeln(
            "Sunulan verilerde eksik veya belirsiz kalan noktaları belirt ve netleştirmek için kullanıcıya spesifik sorular sor. bu soruları madde madde sor. herbir soru birbirinden farklı olmalı",
          )
          ..writeln("")
          ..writeln("Her aşamada net, anlaşılır ve empatik bir dil kullan.");

    final raw = await _postToChatGPT(prompt.toString());
    // “1. …  2. …” formatını parçalara ayır
    final parts =
        raw
            .split(RegExp(r'\n(?=\d+\.)'))
            .map((p) => p.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim())
            .where((p) => p.isNotEmpty)
            .toList();
    return parts;
  }

  /// 2. Adım: Kullanıcının cevaplarıyla birlikte nihai tıbbi değerlendirmeyi üretir.
  Future<String> getFinalEvaluation(
    Map<String, String> inputs,
    List<String> answers,
  ) async {
    final buffer =
        StringBuffer()
          ..writeln("Kullanıcı bilgileri:")
          ..writeln("- Boy: ${inputs['Boy']}")
          ..writeln("- Yaş: ${inputs['Yaş']}")
          ..writeln("- Kilo: ${inputs['Kilo']}")
          ..writeln("- Şikayet: ${inputs['Şikayet']}")
          ..writeln("- Şikayet Süresi: ${inputs['Şikayet Süresi']}")
          ..writeln("- Mevcut İlaçlar: ${inputs['Mevcut İlaçlar']}")
          ..writeln("")
          ..writeln("Kullanıcının takip sorulara verdiği cevaplar:")
          ..writeAll(
            answers.asMap().entries.map((e) => "${e.key + 1}. ${e.value}"),
            "\n",
          )
          ..writeln("")
          ..writeln(
            "Yukarıdaki tüm bilgileri dikkate alarak kapsamlı bir tıbbi değerlendirme yap ve önerilerde bulun hastanın sikayetini çözmeye çalış.",
          );

    final result = await _postToChatGPT(buffer.toString());
    return result.trim();
  }

  /// Ortak: Bir prompt’u ChatGPT’ye gönderir ve cevabını döner.
  Future<String> _postToChatGPT(String content) async {
    final response = await http.post(
      _endpoint,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'Sen bir tıbbi asistansın.'},
          {'role': 'user', 'content': content},
        ],
        'max_tokens': 1000,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAI API hata: ${response.statusCode} ${response.body}',
      );
    }

    // 1) Byte dizisini UTF-8 ile decode et
    final utf8Body = utf8.decode(response.bodyBytes);
    // 2) JSON parse
    final data = jsonDecode(utf8Body) as Map<String, dynamic>;
    return (data['choices'][0]['message']['content'] as String?)?.trim() ?? '';
  }
}
