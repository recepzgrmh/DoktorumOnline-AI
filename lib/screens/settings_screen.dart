import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final OpenAI _openAI;
  final ChatUser _currentUser = ChatUser(
    id: '1',
    firstName: 'recep',
    lastName: 'özgür',
  );
  final ChatUser _gptChatUser = ChatUser(
    id: '2',
    firstName: 'Chat',
    lastName: 'GPT',
  );
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _openAI = OpenAI.instance.build(
      token: dotenv.env['OPENAI_API_KEY']!,
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 10)),
      enableLog: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CHAT DEMO')),
      body: DashChat(
        currentUser: _currentUser,
        messages: _messages,
        onSend: getChatResponse,
        messageOptions: MessageOptions(
          // Kullanıcının (currentUser) balonundaki yazı teal olsun
          currentUserTextColor: Colors.teal,
          // Diğer balonlardaki (assistant) yazı beyaz olsun
          textColor: Colors.white,

          // Kendi dekorasyonumuzu burada veriyoruz
          messageDecorationBuilder: (
            ChatMessage message,
            ChatMessage? previous,
            ChatMessage? next,
          ) {
            final bool isMe = message.user.id == _currentUser.id;
            return BoxDecoration(
              // Kullanıcı mesajı beyaz, AI mesajı teal arka plan
              color: isMe ? Colors.white : Colors.teal,
              // Kullanıcı border teal, AI border beyaz
              border: Border.all(
                width: 2,
                color: isMe ? Colors.teal : Colors.white,
              ),
              borderRadius: BorderRadius.circular(18),
            );
          },
        ),
      ),
    );
  }

  Future<void> getChatResponse(ChatMessage userMsg) async {
    // 1. UI'ya önce kullanıcı mesajını ekle
    setState(() => _messages.insert(0, userMsg));

    // 2. Tüm geçmişi OpenAI'ya uygun [ {'role':'user'|'assistant','content':'…'}, … ] formatında hazırla
    final history =
        _messages.reversed.map((msg) {
          return {
            'role': msg.user.id == _currentUser.id ? 'user' : 'assistant',
            'content': msg.text,
          };
        }).toList();

    // 3. İsteği oluştur
    final request = ChatCompleteText(
      model: Gpt4oMiniChatModel(),
      messages: history,
      maxToken: 200,
    );

    // 4. Try/catch ile hatayı yakala, sonuç boş mu diye kontrol et, log bas
    try {
      final resp = await _openAI.onChatCompletion(request: request);
      if (resp == null || resp.choices.isEmpty) {
        debugPrint('⚠️ OpenAI’dan choices dönmedi');
        return;
      }

      final aiContent = resp.choices.first.message?.content;
      if (aiContent == null || aiContent.trim().isEmpty) {
        debugPrint('⚠️ OpenAI mesaj içeriği boş geldi');
        return;
      }

      // 5. Gelen cevabı UI’a ekle
      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            user: _gptChatUser,
            createdAt: DateTime.now(),
            text: aiContent.trim(),
          ),
        );
      });
    } catch (e, st) {
      debugPrint('❌ OpenAI çağrısında hata: $e\n$st');
    }
  }
}
