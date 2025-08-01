// lib/services/openai_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:login_page/services/token_service.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:openai_dart/openai_dart.dart';

class OpenAIService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY']!;
  // (Eski Yöntem)
  final Uri _endpoint = Uri.parse('https://api.openai.com/v1/chat/completions');
  final TokenService _tokenService = TokenService();
  // YÖNTEM 2: OpenAI Dart Client ile
  late final OpenAIClient client;
  OpenAIService() {
    client = OpenAIClient(apiKey: _apiKey);
  }

  // şikayet alakalı mı alaksız mı sorgusu
  Future<bool> _isComplaintMedical(
    String complaint, {
    String? userId,
    String? userEmail,
  }) async {
    // Yapay zekadan sadece 'EVET' veya 'HAYIR' yanıtı bekliyoruz.
    final validationPrompt = "ai_prompt_validation".tr(args: [complaint]);

    final response = await http.post(
      _endpoint,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5',
        'messages': [
          {'role': 'user', 'content': validationPrompt},
        ],
        'max_tokens': 5,
        'temperature': 0,
      }),
    );

    if (response.statusCode != 200) {
      // Hata durumunda, varsayılan olarak tıbbi kabul edip devam et.
      return true;
    }

    final utf8Body = utf8.decode(response.bodyBytes);
    final data = jsonDecode(utf8Body) as Map<String, dynamic>;
    final content =
        (data['choices'][0]['message']['content'] as String?)?.trim() ?? '';

    if (data['usage'] != null) {
      final usage = data['usage'];
      _tokenService.logTokenUsage(
        userEmail: userEmail,
        functionName: '_isComplaintMedical',
        model: data['model'],
        promptTokens: usage['prompt_tokens'],
        completionTokens: usage['completion_tokens'],
        totalTokens: usage['total_tokens'],
        userId: userId,
      );
    }
    // Yanıt 'EVET' ise true, değilse false döner.
    return content.toLowerCase() == 'yes'.tr();
  }

  /// 1. Adım: Kullanıcı verilerindeki eksik/ belirsiz noktaları
  /// madde madde sorulara dönüştürür.
  Future<List<String>> getFollowUpQuestions(
    Map<String, String> profileData,
    Map<String, String> complaintData,
    String userName,
    Map<String, String>? fileAnalysis, {
    String? userId,
    String? userEmail,
  }) async {
    print('GELEN PROFİL DATASI: $profileData');
    final String userComplaint = complaintData['Şikayet'] ?? "";

    final bool isMedical = await _isComplaintMedical(
      userComplaint,
      userId: userId,
      userEmail: userEmail,
    );
    if (!isMedical) {
      // Eğer şikayet tıbbi değilse, JSON'dan aldığımız hata mesajını döndürüp işlemi bitiriyoruz.
      return ["invalid_complaint_error".tr()];
    }
    // —— 1) Prompt'u oluştur ———
    final prompt =
        StringBuffer()
          ..writeln('ai_prompt_user_profile_info'.tr())
          ..writeln("- ${'ai_prompt_height'.tr()}: ${profileData['Boy']}")
          ..writeln("- ${'ai_prompt_age'.tr()}: ${profileData['Yaş']}")
          ..writeln("- ${'ai_prompt_weight'.tr()}: ${profileData['Kilo']}")
          ..writeln("- ${'ai_prompt_gender'.tr()}: ${profileData['Cinsiyet']}")
          ..writeln(
            "- ${'ai_prompt_blood_type'.tr()}: ${profileData['Kan Grubu']}",
          )
          ..writeln(
            "- ${'ai_prompt_smoke_type'.tr()}: ${profileData['Sigara Kullanımı']}",
          )
          ..writeln(
            "- ${'ai_prompt_alcohol_type'.tr()}: ${profileData['Alkol Kullanımı']}",
          )
          ..writeln(
            "- ${'ai_prompt_chronic_illness'.tr()}: ${profileData['Kronik Rahatsızlık']}",
          )
          ..writeln()
          ..writeln('ai_prompt_complaint_info'.tr())
          ..writeln(
            "- ${'ai_prompt_complaint'.tr()}: ${complaintData['Şikayet']}",
          )
          ..writeln(
            "- ${'ai_prompt_complaint_duration'.tr()}: ${complaintData['Şikayet Süresi']}",
          )
          ..writeln(
            "- ${'ai_prompt_current_meds'.tr()}: ${complaintData['Mevcut İlaçlar']}",
          )
          ..writeln();
    if (fileAnalysis != null && fileAnalysis.isNotEmpty) {
      prompt.writeln('ai_prompt_file_analysis_header'.tr());
      fileAnalysis.forEach((key, value) {
        prompt.writeln("- $key: $value");
      });
      prompt.writeln();
    }
    prompt.writeln('ai_prompt_ask_questions_instruction'.tr());

    // —— 2) ChatGPT'den yanıtı al ————————————————————————————
    final raw = await _postToChatGPT(
      prompt.toString(),
      functionName: 'getFollowUpQuestions',
      userId: userId,
      userEmail: userEmail,
    );

    /// —————————————————— CHATGPT YANITI ——————————————————
    print(
      "______________________ChatGPT'den gelen yanıt : $raw __________________________",
    );

    if (raw.contains("invalid_complaint_error".tr())) {
      return [raw];
    }
    // SIKINTI BURDAYDI ÇÖZDÜM :)))
    final parts =
        raw
            .split(RegExp(r'\n\s*\d+\.\s*'))
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();

    // —— 4) Eğer hiç soru yoksa, doğrudan değerlendirme yap —————————
    if (parts.isEmpty) {
      // Hiç soru yoksa, doğrudan selamlama ve değerlendirme mesajı oluştur
      final greeting = "ai_greeting_no_questions".tr(args: [userName]);
      // Doğrudan değerlendirme yap
      final evaluation = await getFinalEvaluation(
        profileData,
        complaintData,
        userId: userId,
        userEmail: userEmail,
        [], // Boş cevap listesi
        fileAnalysis,
      );

      return [greeting + evaluation];
    }

    // —— 5) Selamlama + ilk soruyu tek mesaja dönüştür —————————
    final greeting = "ai_intro_greeting".tr(args: [userName]);

    parts[0] = greeting + parts[0]; // ilk soruyla selamlamayı birleştir

    // —— 6) Geri dön ————————————————————————————————————————————
    return parts;
  }

  /// 2. Adım: kullanıcın mesajlarını değerlendirip tıbbi yanıt alma
  Future<String> getFinalEvaluation(
    Map<String, String> profileData,
    Map<String, String> complaintData,
    List<String> answers,
    Map<String, String>? fileAnalysis, {
    String? userId,
    String? userEmail,
  }) async {
    final prompt =
        StringBuffer()
          ..writeln('ai_prompt_user_profile_info'.tr())
          ..writeln("- ${'ai_prompt_height'.tr()}: ${profileData['Boy']}")
          ..writeln("- ${'ai_prompt_age'.tr()}: ${profileData['Yaş']}")
          ..writeln("- ${'ai_prompt_weight'.tr()}: ${profileData['Kilo']}")
          ..writeln("- ${'ai_prompt_gender'.tr()}: ${profileData['Cinsiyet']}")
          ..writeln(
            "- ${'ai_prompt_blood_type'.tr()}: ${profileData['Kan Grubu']}",
          )
          ..writeln(
            "- ${'ai_prompt_smoke_type'.tr()}: ${profileData['Sigara Kullanımı']}",
          )
          ..writeln(
            "- ${'ai_prompt_alcohol_type'.tr()}: ${profileData['Alkol Kullanımı']}",
          )
          ..writeln(
            "- ${'ai_prompt_chronic_illness'.tr()}: ${profileData['Kronik Rahatsızlık']}",
          )
          ..writeln()
          ..writeln('ai_prompt_complaint_info'.tr())
          ..writeln(
            "- ${'ai_prompt_complaint'.tr()}: ${complaintData['Şikayet']}",
          )
          ..writeln(
            "- ${'ai_prompt_complaint_duration'.tr()}: ${complaintData['Şikayet Süresi']}",
          )
          ..writeln(
            "- ${'ai_prompt_current_meds'.tr()}: ${complaintData['Mevcut İlaçlar']}",
          )
          ..writeln()
          ..writeln(
            "Kullanıcının takip sorularına verdiği cevaplar:",
          ) // Bu kısım AI'a gittiği için çevrilebilir veya sabit kalabilir
          ..writeAll(
            answers.asMap().entries.map((e) => "${e.key + 1}. ${e.value}"),
            "\n",
          )
          ..writeln();
    if (fileAnalysis != null && fileAnalysis.isNotEmpty) {
      prompt.writeln('ai_prompt_file_analysis_header'.tr());
      fileAnalysis.forEach((key, value) {
        prompt.writeln("- $key: $value");
      });
      prompt.writeln();
    }
    prompt
      ..writeln('ai_prompt_final_evaluation_instruction'.tr())
      ..writeln('ai_prompt_final_evaluation_start_sentence'.tr());

    final result = await _postToChatGPT(
      prompt.toString(),
      functionName: 'getFinalEvaluation',
      userId: userId,
      userEmail: userEmail,
    );
    return result.trim();
  }

  /// Ortak: Bir prompt'u ChatGPT'ye gönderir ve cevabını döner.
  Future<String> _postToChatGPT(
    String content, {
    required String functionName,
    String? userId,
    String? userEmail,
  }) async {
    final response = await http.post(
      _endpoint,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {'role': 'system', 'content': 'ai_system_prompt_medical'.tr()},
          {'role': 'user', 'content': content},
        ],
        'max_tokens': 3000,
        'temperature': 0,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAI API hata: ${response.statusCode} ${response.body}',
      );
    }

    final utf8Body = utf8.decode(response.bodyBytes);
    // 2) JSON parse
    final data = jsonDecode(utf8Body) as Map<String, dynamic>;

    if (data['usage'] != null) {
      final usage = data['usage'];
      _tokenService.logTokenUsage(
        userEmail: userEmail,
        functionName: functionName,
        model: data['model'],
        promptTokens: usage['prompt_tokens'],
        completionTokens: usage['completion_tokens'],
        totalTokens: usage['total_tokens'],
        userId: userId,
      );
    }
    return (data['choices'][0]['message']['content'] as String?)?.trim() ?? '';
  }

  Future<String> getChatResponse(
    List<Map<String, dynamic>> messages, {
    String? userId,
    String? userEmail,
  }) async {
    // Bu fonksiyon _postToChatGPT'ye çok benziyor, onu kullanabiliriz.
    // Gelen mesajları tek bir 'content' bloğuna dönüştürmek yerine
    // direkt 'messages' listesi olarak göndereceğiz.

    final response = await http.post(
      _endpoint,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini', // veya gpt-4o, hangisini istersen
        'messages': messages, // Direkt mesaj listesini gönder
        'max_tokens': 1000,
        'temperature': 0.7, // Serbest sohbette biraz daha yaratıcı olabilir
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAI API hatası: ${response.statusCode} ${response.body}',
      );
    }

    final utf8Body = utf8.decode(response.bodyBytes);
    final data = jsonDecode(utf8Body) as Map<String, dynamic>;

    if (data['usage'] != null) {
      final usage = data['usage'];
      _tokenService.logTokenUsage(
        userEmail: userEmail,
        functionName: 'getChatResponse',
        model: data['model'],
        promptTokens: usage['prompt_tokens'],
        completionTokens: usage['completion_tokens'],
        totalTokens: usage['total_tokens'],
        userId: userId,
      );
    }

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

  Map<String, String> _parseAnalysisResponse(String reply) {
    final rejectionMessage = 'non_medical_document_error'.tr();
    if (reply.trim() == rejectionMessage) {
      return {'Hata': rejectionMessage};
    }

    final Map<String, String> analysisResults = {};
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

  Future<Map<String, String>> analyzePdf(
    String filePath, {
    String? userId,
    String? userEmail,
  }) async {
    final file = File(filePath);
    final fullText = await extractTextFromPdf(file);

    if (fullText.trim().isEmpty) {
      return {'Hata': 'PDF içeriği okunamadı veya boş.'};
    }

    final chunks = chunkText(fullText, 3000);
    Map<String, String> analysisResults = {};
    final systemPrompt = 'ai_prompt_file_analysis_system_prompt'.tr();
    for (var part in chunks) {
      try {
        final res = await client.createChatCompletion(
          request: CreateChatCompletionRequest(
            model: ChatCompletionModel.model(ChatCompletionModels.gpt4o),
            messages: [
              ChatCompletionMessage.system(content: systemPrompt),
              ChatCompletionMessage.user(
                content: ChatCompletionUserMessageContent.parts([
                  ChatCompletionMessageContentPart.text(text: part),
                ]),
              ),
            ],
            temperature: 0,
            maxTokens: 3000,
          ),
        );

        final usage = res.usage;
        if (usage != null) {
          _tokenService.logTokenUsage(
            functionName: 'analyzePdf',
            model: res.model,
            promptTokens: usage.promptTokens,
            completionTokens: usage.completionTokens ?? 0,
            totalTokens: usage.totalTokens,
            userId: userId,
            userEmail: userEmail,
          );
        }

        final reply = res.choices.first.message.content?.trim() ?? '';

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

  Future<Map<String, String>> analyzeImage(
    String imagePath, {
    String? userId,
    String? userEmail,
  }) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      final systemPrompt = 'ai_prompt_file_analysis_system_prompt'.tr();
      final userPrompt = 'ai_prompt_analyze_image_request'.tr();
      // `openai_dart` client'ını kullanarak API'ye istek gönder
      final res = await client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.model(
            ChatCompletionModels.chatgpt4oLatest,
          ),
          messages: [
            // Lokalize edilmiş değişkenleri kullan
            ChatCompletionMessage.system(content: systemPrompt),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.parts([
                ChatCompletionMessageContentPart.text(
                  text: userPrompt, // Burası da lokalize edildi
                ),
                ChatCompletionMessageContentPart.image(
                  imageUrl: ChatCompletionMessageImageUrl(
                    url: 'data:image/jpeg;base64,$base64Image',
                  ),
                ),
              ]),
            ),
          ],
          temperature: 0,
          maxTokens: 3000,
        ),
      );

      final usage = res.usage;
      if (usage != null) {
        _tokenService.logTokenUsage(
          userEmail: userEmail,
          functionName: 'analyzeImage',
          model: res.model,
          promptTokens: usage.promptTokens,
          completionTokens: usage.completionTokens ?? 0,
          totalTokens: usage.totalTokens,
          userId: userId,
        );
      }
      final reply = res.choices.first.message.content?.trim() ?? '';

      return _parseAnalysisResponse(reply);
    } catch (e) {
      print('Resim analizi sırasında hata oluştu: $e');
      return {'Hata': 'Resim analizi sırasında bir hata oluştu: $e'};
    }
  }
}
