// lib/services/openai_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:openai_dart/openai_dart.dart';

class OpenAIService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY']!;
  // YÖNTEM 1: HTTP Client ile (Eski Yöntem)
  final Uri _endpoint = Uri.parse('https://api.openai.com/v1/chat/completions');

  // YÖNTEM 2: OpenAI Dart Client ile (Modern ve Tercih Edilen)
  late final OpenAIClient client;
  OpenAIService() {
    client = OpenAIClient(apiKey: _apiKey);
  }

  /// 1. Adım: Kullanıcı verilerindeki eksik/ belirsiz noktaları
  /// madde madde sorulara dönüştürür.
  Future<List<String>> getFollowUpQuestions(
    // ... Bu fonksiyonun içeriği aynı kalır ...
    Map<String, String> profileData,
    Map<String, String> complaintData,
    String userName,
    Map<String, String>? fileAnalysis,
  ) async {
    // —— 1) Prompt'u oluştur ————————————————————————————
    final prompt =
        StringBuffer()
          ..writeln("Kullanıcı profil bilgileri:")
          ..writeln("- Boy: ${profileData['Boy']}")
          ..writeln("- Yaş: ${profileData['Yaş']}")
          ..writeln("- Kilo: ${profileData['Kilo']}")
          ..writeln("- Cinsiyet: ${profileData['Cinsiyet']}")
          ..writeln("- Kan Grubu: ${profileData['Kan Grubu']}")
          ..writeln(
            "- Kronik Rahatsızlık: ${profileData['Kronik Rahatsızlık']}",
          )
          ..writeln()
          ..writeln("Şikayet bilgileri:")
          ..writeln("- Şikayet: ${complaintData['Şikayet']}")
          ..writeln("- Şikayet Süresi: ${complaintData['Şikayet Süresi']}")
          ..writeln("- Mevcut İlaçlar: ${complaintData['Mevcut İlaçlar']}")
          ..writeln();
    if (fileAnalysis != null && fileAnalysis.isNotEmpty) {
      prompt.writeln(
        "Ayrıca kullanıcı tarafından yüklenen dosyanın analizi de aşağıdadır:",
      );
      fileAnalysis.forEach((key, value) {
        prompt.writeln("- $key: $value");
      });
      prompt.writeln();
    }
    prompt
      ..writeln(
        "Lütfen kullanıcının sağladığı tüm hasta bilgilerini dikkatle incele ve aşağıdaki adımları takip et:",
      )
      ..writeln()
      ..writeln(
        "Sunulan verilerde eksik veya belirsiz kalan noktaları belirt ve netleştirmek için kullanıcıya spesifik sorular sor. Bu soruları madde madde sor. Her bir soru birbirinden farklı olmalı.",
      )
      ..writeln()
      ..writeln(
        // Burada hâlâ talimat veriyoruz; selamlama ve ilk soruyu kod tarafında birleştireceğiz
        "Her aşamada net, anlaşılır ve empatik bir dil kullan.",
      );

    // —— 2) ChatGPT'den yanıtı al ————————————————————————————
    final raw = await _postToChatGPT(prompt.toString());

    // —— 3) "1. … 2. …" yapısını listeye çevir ——————————————————
    final parts =
        raw
            .split(RegExp(r'\n(?=\d+\.)')) // "\n1.", "\n2."'lerden kes
            .map((p) => p.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim())
            .where((p) => p.isNotEmpty)
            .toList();

    // —— 4) Eğer hiç soru yoksa, doğrudan değerlendirme yap —————————
    if (parts.isEmpty) {
      // Hiç soru yoksa, doğrudan selamlama ve değerlendirme mesajı oluştur
      final greeting =
          "Merhaba $userName, ben kişisel sağlık danışmanın DoktorumOnline. "
          "Verdiğiniz bilgiler yeterli görünüyor. Şikayetinizi değerlendirip size önerilerde bulunacağım.\n\n";

      // Doğrudan değerlendirme yap
      final evaluation = await getFinalEvaluation(
        profileData,
        complaintData,

        [], // Boş cevap listesi
        fileAnalysis,
      );

      return [greeting + evaluation];
    }

    // —— 5) Selamlama + ilk soruyu tek mesaja dönüştür —————————
    final greeting =
        "Merhaba $userName, ben kişisel sağlık danışmanın DoktorumOnline. "
        "Şikayetine daha sağlıklı yorum yapabilmem için bazı sorular soracağım. "
        "Bu sorulara cevap verirsen daha iyi sonuç verebilirim.\n\n";

    parts[0] = greeting + parts[0]; // ilk soruyla selamlamayı birleştir

    // —— 6) Geri dön ————————————————————————————————————————————
    return parts;
  }

  /// 2. Adım: kullanıcın mesajlarını değerlendirip tıbbi yanıt alma
  Future<String> getFinalEvaluation(
    // ... Bu fonksiyonun içeriği aynı kalır ...
    Map<String, String> profileData,
    Map<String, String> complaintData,
    List<String> answers,
    Map<String, String>? fileAnalysis,
  ) async {
    final prompt =
        StringBuffer()
          ..writeln("Kullanıcı profil bilgileri:")
          ..writeln("- Boy: ${profileData['Boy']}")
          ..writeln("- Yaş: ${profileData['Yaş']}")
          ..writeln("- Kilo: ${profileData['Kilo']}")
          ..writeln("- Cinsiyet: ${profileData['Cinsiyet']}")
          ..writeln("- Kan Grubu: ${profileData['Kan Grubu']}")
          ..writeln(
            "- Kronik Rahatsızlık: ${profileData['Kronik Rahatsızlık']}",
          )
          ..writeln()
          ..writeln("Şikayet bilgileri:")
          ..writeln("- Şikayet: ${complaintData['Şikayet']}")
          ..writeln("- Şikayet Süresi: ${complaintData['Şikayet Süresi']}")
          ..writeln("- Mevcut İlaçlar: ${complaintData['Mevcut İlaçlar']}")
          ..writeln()
          ..writeln("Kullanıcının takip sorularına verdiği cevaplar:")
          ..writeAll(
            answers.asMap().entries.map((e) => "${e.key + 1}. ${e.value}"),
            "\n",
          )
          ..writeln();
    if (fileAnalysis != null && fileAnalysis.isNotEmpty) {
      prompt.writeln(
        "Ayrıca kullanıcı tarafından yüklenen dosyanın analizi de aşağıdadır:",
      );
      fileAnalysis.forEach((key, value) {
        prompt.writeln("- $key: $value");
      });
      prompt.writeln();
    }
    prompt
      ..writeln(
        "Yukarıdaki tüm bilgileri (profil, şikayet, soru-cevaplar VE VARSA DOSYA ANALİZİ) birlikte HARMANLAYARAK kapsamlı bir tıbbi değerlendirme yap ve önerilerde bulun. "
        "Hastanın şikayetini hafifletecek öneriler ver; gerekirse doktora yönlendir.",
      )
      ..writeln(
        "Yanıtına mutlaka şu cümleyle BAŞLA ve kullanıcı bilgilerini yeniden listeleme: "
        "\"Verdiğiniz bilgilere dayanarak çıkarımlarım şöyle:\"",
      );

    final result = await _postToChatGPT(prompt.toString());
    return result.trim();
  }

  /// Ortak: Bir prompt'u ChatGPT'ye gönderir ve cevabını döner.
  Future<String> _postToChatGPT(String content) async {
    // ... Bu fonksiyonun içeriği aynı kalır ...
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

  // ————————————————————————————————————————————————————————————
  // PDF ve Resim Analizi Bölümü
  // ————————————————————————————————————————————————————————————

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

  /// **YENİ:** PDF ve Resim analizinden gelen yanıtları ayrıştıran ortak fonksiyon.
  Map<String, String> _parseAnalysisResponse(String reply) {
    final Map<String, String> analysisResults = {};
    // Yanıtı "##" karakterine göre bölerek başlıkları ve içerikleri ayır
    final sections = reply.split('##');

    for (var section in sections) {
      if (section.trim().isEmpty) continue;

      final lines = section.split('\n');
      if (lines.isEmpty) continue;

      final title = lines[0].trim();
      final content = lines.skip(1).join('\n').trim();

      if (title.isNotEmpty && content.isNotEmpty) {
        analysisResults[title] = content;
      }
    }
    return analysisResults;
  }

  Future<Map<String, String>> analyzePdf(String filePath) async {
    final file = File(filePath);
    final fullText = await extractTextFromPdf(file);

    if (fullText.trim().isEmpty) {
      return {'Hata': 'PDF içeriği okunamadı veya boş.'};
    }

    // PDF metnini 3000 kelimelik parçalara ayır
    final chunks = chunkText(fullText, 3000);
    Map<String, String> analysisResults = {};

    for (var part in chunks) {
      try {
        final res = await client.createChatCompletion(
          request: CreateChatCompletionRequest(
            model: ChatCompletionModel.model(
              ChatCompletionModels.gpt4o,
            ), // Model güncellendi
            messages: [
              ChatCompletionMessage.system(
                content:
                    "Bir doktor titizliğiyle gelen metni detaylıca incele. Lütfen aşağıdaki başlıklar altında kapsamlı bir analiz yap, Kullanıcının Anlayabileceği Yalın bir dil kullan. Her başlığı '##' işareti ile başlat ve içeriğini altına yaz:\n\n"
                    "## Genel Değerlendirme\n"
                    "## Tespit Edilen Durumlar\n"
                    "## Risk Faktörleri\n"
                    "## Öneriler\n"
                    "## Takip Önerileri\n\n"
                    "Kullanıcının anlayabileceği sade bir dil kullan, ancak gerekli tıbbi terimleri de açıklayarak kullan. Her bölüm için detaylı ve kapsamlı bilgi ver.",
              ),
              ChatCompletionMessage.user(
                content: ChatCompletionUserMessageContent.parts([
                  ChatCompletionMessageContentPart.text(text: part),
                ]),
              ),
            ],
            temperature: 0.3,
            maxTokens: 3000,
          ),
        );

        final reply = res.choices.first.message.content?.trim() ?? '';

        // **DEĞİŞİKLİK:** Artık ortak parser fonksiyonunu kullanıyoruz.
        final parsedPart = _parseAnalysisResponse(reply);
        analysisResults.addAll(parsedPart);
      } catch (e) {
        // Hata durumunda, mevcut sonuçlara hata bilgisini ekle
        analysisResults['Hata (Bölüm İşlenemedi)'] =
            'Bu bölüm işlenirken bir hata oluştu: $e';
      }
    }

    return analysisResults;
  }

  /// **DEĞİŞİKLİK:** Bu fonksiyon `analyzePdf` gibi çalışacak şekilde tamamen yeniden yazıldı.
  Future<Map<String, String>> analyzeImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      // `openai_dart` client'ını kullanarak API'ye istek gönder
      final res = await client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.model(
            ChatCompletionModels.chatgpt4oLatest,
          ),
          messages: [
            ChatCompletionMessage.system(
              content:
                  // PDF analiziyle aynı sistem prompt'unu kullanıyoruz
                  "Bir doktor titizliğiyle gelen tıbbi raporu (resim formatında) detaylıca incele. Lütfen aşağıdaki başlıklar altında kapsamlı bir analiz yap, Kullanıcının Anlayabileceği Yalın bir dil kullan. Her başlığı '##' işareti ile başlat ve içeriğini altına yaz:\n\n"
                  "## Genel Değerlendirme\n"
                  "## Tespit Edilen Durumlar\n"
                  "## Risk Faktörleri\n"
                  "## Öneriler\n"
                  "## Takip Önerileri\n\n"
                  "Kullanıcının anlayabileceği sade bir dil kullan, ancak gerekli tıbbi terimleri de açıklayarak kullan. Her bölüm için detaylı ve kapsamlı bilgi ver.",
            ),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.parts([
                ChatCompletionMessageContentPart.text(
                  text: "Lütfen bu tıbbi rapor resmini analiz et.",
                ),
                ChatCompletionMessageContentPart.image(
                  // Resmi base64 formatında gönderiyoruz
                  imageUrl: ChatCompletionMessageImageUrl(
                    url: 'data:image/jpeg;base64,$base64Image',
                  ),
                ),
              ]),
            ),
          ],
          temperature: 0.3,
          maxTokens: 3000, // Token limitini PDF ile aynı tuttuk
        ),
      );

      final reply = res.choices.first.message.content?.trim() ?? '';

      // Yanıtı ayrıştırmak için ortak fonksiyonu kullan
      return _parseAnalysisResponse(reply);
    } catch (e) {
      // Hata yönetimi
      print('Resim analizi sırasında hata oluştu: $e');
      return {'Hata': 'Resim analizi sırasında bir hata oluştu: $e'};
    }
  }

  /// **KALDIRILDI:** Bu fonksiyonun yerine artık `_parseAnalysisResponse` kullanılıyor.
  // Map<String, String> _parseImageAnalysisResponse(String content) { ... }
}
