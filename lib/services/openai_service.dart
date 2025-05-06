import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  final _apiKey = dotenv.env['OPENAI_API_KEY']!;
  final _endpoint = Uri.parse('https://api.openai.com/v1/chat/completions');

  Future<String> analyzeSymptoms(Map<String, String> inputs) async {
    final prompt =
        StringBuffer()
          ..writeln("Kullanıcı bilgileri:")
          ..writeln("- Boy: ${inputs['Boy']}")
          ..writeln("- Yaş: ${inputs['Yaş']}")
          ..writeln("- Kilo: ${inputs['Kilo']}")
          ..writeln("- Şikayet: ${inputs['Şikayet']}")
          ..writeln("- Şikayet Süresi: ${inputs['Şikayetin Süresi']}")
          ..writeln("- Mevcut İlaçlar: ${inputs['Mevcut İlaçlar']}")
          ..writeln("")
          ..writeln(
            "Lütfen kullanıcının sağladığı tüm hasta bilgilerini dikkatle incele ve aşağıdaki adımları takip ederek kapsamlı bir tıbbi değerlendirme yap:",
          )
          ..writeln(
            "1. Bilgi Tamamlama: Sunulan verilerde eksik veya belirsiz kalan noktaları belirt ve netleştirmek için kullanıcıya spesifik sorular sor.",
          )
          ..writeln(
            "2. Tıbbi Açıklama: Mevcut semptomlar, bulgular ve öykü ışığında tıbbi terimleri anlaşılır bir şekilde açıkla.",
          )
          ..writeln(
            "3. Olası Teşhis ve Risk Analizi: En muhtemel tanıları, alternatif tanıları ve bunların olası risklerini değerlendir; fizyopatolojiyi, yaygınlığını ve aciliyet gerektiren durumları vurgula.",
          )
          ..writeln(
            "4. Öneriler ve Yönlendirme: Kullanıcının hangi branştaki bir uzmana (ör. dahiliye, kardiyoloji, nöroloji vb.) görünmesi gerektiğini belirt; birinci basamak mı yoksa acil servise mi başvurması gerektiğini açıkla; evde uygulanabilecek temel destekleyici önlemlerden bahset.",
          )
          ..writeln(
            "5. İzleme ve Takip: Kullanıcının verdiği yanıtlara göre sonraki adımları yeniden değerlendir ve gerektiğinde ilave tetkik veya konsültasyon öner.",
          )
          ..writeln("")
          ..writeln("Her aşamada net, anlaşılır ve empatik bir dil kullan.");

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
          {'role': 'user', 'content': prompt.toString()},
        ],
        'max_tokens': 1000,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      // 1. ham byteları UTF-8 ile decode et
      final utf8Body = utf8.decode(response.bodyBytes);
      // 2. sonra JSON decode
      final data = jsonDecode(utf8Body) as Map<String, dynamic>;
      final content =
          (data['choices'][0]['message']['content'] as String?) ?? '';
      return content.trim();
    } else {
      throw Exception(
        'OpenAI API hata: ${response.statusCode} ${response.body}',
      );
    }
  }
}
