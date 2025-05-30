// lib/services/openai_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:openai_dart/openai_dart.dart';

class OpenAIService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY']!;
  final Uri _endpoint = Uri.parse('https://api.openai.com/v1/chat/completions');

  late final OpenAIClient client;
  OpenAIService() {
    client = OpenAIClient(apiKey: _apiKey);
  }

  /// 1. Adım: Kullanıcı verilerindeki eksik/ belirsiz noktaları
  /// madde madde sorulara dönüştürür.
  /// burası sorularla alakalı
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
          ..writeln("- Cinsiyet: ${inputs['Cinsiyet']}")
          ..writeln("- Kan Grubu: ${inputs['Kan Grubu']}")
          ..writeln("- Kronik Rahatsızlık: ${inputs['Kronik Rahatsızlık']}")
          ..writeln("")
          ..writeln(
            "Lütfen kullanıcının sağladığı tüm hasta bilgilerini dikkatle incele ve aşağıdaki adımları takip et:",
          )
          ..writeln("")
          ..writeln(
            "Sunulan verilerde eksik veya belirsiz kalan noktaları belirt ve netleştirmek için kullanıcıya spesifik sorular sor. bu soruları madde madde sor. herbir soru birbirinden farklı olmalı.",
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

  /// 2. Adım: kullanıcın mesajlarını değerlendirip tıbbi yanıt alma
  /// burası son mesaj
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
          ..writeln("- Cinsiyet: ${inputs['Cinsiyet']}")
          ..writeln("- Kan Grubu: ${inputs['Kan Grubu']}")
          ..writeln("- Kronik Hastalık: ${inputs['Kronik Rahatsızlık']}")
          ..writeln("")
          ..writeln("Kullanıcının takip sorulara verdiği cevaplar:")
          ..writeAll(
            answers.asMap().entries.map((e) => "${e.key + 1}. ${e.value}"),
            "\n",
          )
          ..writeln("")
          ..writeln(
            "Yukarıdaki tüm bilgileri dikkate alarak kapsamlı bir tıbbi değerlendirme yap ve önerilerde bulun hastanın sikayetini çözmeye çalış.  eğer hastanın doktora gitmesi gerekiyorsa bile onun şikayetini azaltacak şeyler öner",
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

  //
  //
  //
  //
  //
  Future<String> extractTextFromPdf(File file) async {
    final bytes = await file.readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final String text = PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
  }

  List<String> chunkText(String text, int chunkSize) {
    List<String> words = text.split(RegExp(r'\s+'));
    List<String> chunks = [];
    for (var i = 0; i < words.length; i += chunkSize) {
      int end = (i + chunkSize < words.length) ? i + chunkSize : words.length;
      chunks.add(words.sublist(i, end).join(' '));
    }
    return chunks;
  }

  Future<String> analyzePdf(String filePath) async {
    final file = File(filePath);
    final fullText = await extractTextFromPdf(file);

    // Eğer metin boşsa erken dön
    if (fullText.trim().isEmpty) {
      return 'PDF içeriği okunamadı veya boş.';
    }

    final chunks = chunkText(fullText, 1500);
    StringBuffer aggregated = StringBuffer();

    for (var part in chunks) {
      try {
        final res = await client.createChatCompletion(
          request: CreateChatCompletionRequest(
            model: ChatCompletionModel.model(
              ChatCompletionModels.chatgpt4oLatest,
            ),
            messages: [
              ChatCompletionMessage.system(
                content:
                    "Bir doktor titizliğiyle gelen metni incele. Kullanıcının anlayabileceği sade bir dille, karşılaşılabilecek olası durumlardan bahset. Anlaşılması güç tıbbi terimler kullanmaktan kaçın. Eğer metinde bir sorun tespit edersen detaylıca açıkla; aksi halde kullanıcının genel olarak sağlıklı olduğunu kısaca belirt. Sorunlu gördüğün kısımlar hakkında ayrıntılı yorum yap, diğer bölümler için yalnızca kısa ve öz bilgi ver",
              ),
              ChatCompletionMessage.user(
                content: ChatCompletionUserMessageContent.parts([
                  ChatCompletionMessageContentPart.text(text: part),
                ]),
              ),
            ],
            temperature: 0.0,
            maxTokens: 500,
          ),
        );

        final reply = res.choices.first.message.content?.trim() ?? '';
        aggregated.writeln(reply);
      } catch (e) {
        aggregated.writeln('— Bu bölüm işlenirken bir hata oluştu.');
      }
    }

    return aggregated.toString();
  }
}
