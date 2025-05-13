import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

class OverviewScreen extends StatefulWidget {
  final String response;
  final String uid;
  final String complaintId;

  const OverviewScreen({
    super.key,
    required this.response,
    required this.uid,
    required this.complaintId,
  });

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late final OpenAI _openAI;
  late final String _apiKey;
  bool _emojiShowing = false;

  final ChatUser _currentUser = ChatUser(
    id: '1',
    firstName: 'Recep',
    lastName: 'Özgür',
  );

  final ChatUser _gptChatUser = ChatUser(
    id: '2',
    firstName: 'Chat',
    lastName: 'GPT',
    profileImage: "assets/images/avatar.png",
  );

  String _gptState = 'Çevrimiçi';
  final List<ChatMessage> _messages = [];

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> chatHistory;

  @override
  void initState() {
    super.initState();

    // .env dosyasından API anahtarını al ve kontrol et
    _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (_apiKey.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'API anahtarı bulunamadı! .env dosyasını kontrol edin.',
            ),
          ),
        );
      });
      _emojiShowing = false;
    }

    // OpenAI istemcisini başlat
    _openAI = OpenAI.instance.build(
      token: _apiKey,
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 10)),
      enableLog: true,
    );

    // İlk GPT mesajlarını ekle
    _messages.insert(
      0,
      ChatMessage(
        user: _gptChatUser,
        createdAt: DateTime.now(),
        text: widget.response.isNotEmpty ? widget.response : '[Yanıt boş]',
      ),
    );

    // messages alt-koleksiyonundan canlı stream
    chatHistory =
        _db
            .collection('users')
            .doc(widget.uid)
            .collection('complaints')
            .doc(widget.complaintId)
            .collection('messages')
            .orderBy('sentAt', descending: true)
            .snapshots();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onSendMessage(ChatMessage userMsg) async {
    final messagesRef = _db
        .collection('users')
        .doc(widget.uid)
        .collection('complaints')
        .doc(widget.complaintId)
        .collection("messages");

    setState(() {
      _messages.insert(0, userMsg);
      _gptState = '...yazıyor';
    });

    // Kullanıcının mesajını Firestore'a ekle
    await messagesRef.add({
      'text': userMsg.text,
      'senderId': userMsg.user.id,
      'sentAt': FieldValue.serverTimestamp(),
    });

    // Geçmişi GPT için hazırla
    final history =
        _messages.reversed.map((msg) {
          return {
            'role': msg.user.id == _currentUser.id ? 'user' : 'assistant',
            'content': msg.text,
          };
        }).toList();

    // GPT isteği
    final request = ChatCompleteText(
      model: Gpt4oMiniChatModel(),
      messages: history,
      maxToken: 1000,
    );

    try {
      final resp = await _openAI.onChatCompletion(request: request);

      if (resp == null || resp.choices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ OpenAI’dan yanıt dönmedi')),
        );
        setState(() => _gptState = 'Çevrimiçi');
        return;
      }

      final aiContent = resp.choices.first.message?.content?.trim();
      if (aiContent == null || aiContent.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ OpenAI mesajı boş döndü')),
        );
        setState(() => _gptState = 'Çevrimiçi');
        return;
      }

      // GPT cevabını Firestore'a ekle
      await messagesRef.add({
        'text': aiContent,
        'senderId': _gptChatUser.id,
        'sentAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _messages.insert(
          0,
          ChatMessage(
            user: _gptChatUser,
            createdAt: DateTime.now(),
            text: aiContent,
          ),
        );
        _gptState = 'Çevrimiçi';
      });
    } catch (e, st) {
      debugPrint('❌ OpenAI hata: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OpenAI ile iletişim kurulamadı')),
      );
      setState(() => _gptState = 'Çevrimiçi');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 70,
        elevation: 4,
        backgroundColor: Colors.teal,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundImage: AssetImage('assets/images/avatar.png'),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ChatGPT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.lightGreenAccent.shade200,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _gptState,
                          style: TextStyle(
                            color: Colors.lightGreenAccent.shade200,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.teal.shade50,
        child: DashChat(
          inputOptions: InputOptions(
            sendOnEnter: false,
            sendButtonBuilder:
                (send) =>
                    IconButton(onPressed: send, icon: const Icon(Icons.send)),
            inputDecoration: InputDecoration(
              fillColor: Colors.white,
              hintText: 'Mesajınızı yazın...',
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
            cursorStyle: const CursorStyle(color: Colors.teal),
            inputToolbarStyle: const BoxDecoration(
              color: Color.fromARGB(0, 0, 150, 135),
            ),
            inputToolbarPadding: const EdgeInsets.only(
              top: 16,
              bottom: 20,
              left: 8,
              right: 8,
            ),
            inputToolbarMargin: const EdgeInsets.symmetric(horizontal: 4),
            leading: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _emojiShowing = !_emojiShowing;
                  });
                },
                icon: const Icon(
                  Icons.emoji_emotions_outlined,
                  color: Colors.teal,
                  size: 30,
                ),
              ),
            ],
            trailing: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.attach_file,
                  color: Colors.teal,
                  size: 30,
                ),
              ),
            ],
          ),
          currentUser: _currentUser,
          onSend: _onSendMessage,
          messages: _messages,
          messageOptions: MessageOptions(
            currentUserTextColor: Colors.white,
            textColor: Colors.black,
            messageDecorationBuilder: (
              ChatMessage message,
              ChatMessage? previous,
              ChatMessage? next,
            ) {
              final isMe = message.user.id == _currentUser.id;
              return BoxDecoration(
                color: isMe ? Colors.teal : Colors.grey.shade300,
                boxShadow: const [
                  BoxShadow(offset: Offset(1, 1), blurRadius: 2),
                ],
                border: Border.all(
                  width: 2,
                  color: isMe ? Colors.teal : Colors.white,
                ),
                borderRadius: BorderRadius.circular(18),
              );
            },
          ),
        ),
      ),
    );
  }
}
