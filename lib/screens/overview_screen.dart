// lib/screens/overview_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:login_page/services/openai_service.dart';
import 'package:login_page/widgets/error_widget.dart';
import 'package:login_page/widgets/custom_appBar.dart';

class OverviewScreen extends StatefulWidget {
  final String uid;
  final String complaintId;
  final Map<String, String> inputs;
  final List<String> questions;

  const OverviewScreen({
    super.key,
    required this.uid,
    required this.complaintId,
    required this.inputs,
    required this.questions,
  });

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late final OpenAI _openAI;
  final OpenAIService _service = OpenAIService();
  late final String _apiKey;
  final TextEditingController _textController = TextEditingController();

  String _gptState = 'Çevrimiçi';

  final ChatUser _currentUser = ChatUser(id: '1', firstName: 'Sen');
  final ChatUser _gptChatUser = ChatUser(
    id: '2',
    firstName: 'Sağlık Asistanı',
    profileImage: "assets/images/avatar.png",
  );

  late final CollectionReference<Map<String, dynamic>> _messagesRef;

  // Takip soruları için
  int _currentQIndex = 0;
  final List<String> _answers = [];
  bool _flowComplete = false;

  @override
  void initState() {
    super.initState();

    // burayı uygulama yayınlanırken kaldırmayı unutma
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
    }

    _openAI = OpenAI.instance.build(
      token: _apiKey,
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 10)),
      enableLog: true,
    );

    _messagesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('complaints')
        .doc(widget.complaintId)
        .collection('messages');
  }

  Future<void> _onSendMessage(ChatMessage userMsg) async {
    setState(() => _gptState = '...yazıyor');

    try {
      // 1. Kullanıcı cevabını kaydet
      await _messagesRef.add({
        'text': userMsg.text,
        'senderId': _currentUser.id,
        'sentAt': FieldValue.serverTimestamp(),
      });

      // 2. Eğer sorular akışı bitmediyse
      if (!_flowComplete && _currentQIndex < widget.questions.length) {
        // Gelen cevabı listeye ekle
        _answers.add(userMsg.text.trim());

        // a) Daha soru varsa → bir sonraki soruyu ekle
        if (_currentQIndex + 1 < widget.questions.length) {
          final nextQ = widget.questions[_currentQIndex + 1];
          await _messagesRef.add({
            'text': nextQ,
            'senderId': _gptChatUser.id,
            'sentAt': FieldValue.serverTimestamp(),
          });
          setState(() => _currentQIndex++);
        }
        // b) Son soruya da cevap verildiyse → nihai değerlendirmeyi al ve göster
        else {
          final report = await _service.getFinalEvaluation(
            widget.inputs,
            _answers,
          );
          await _messagesRef.add({
            'text': report,
            'senderId': _gptChatUser.id,
            'sentAt': FieldValue.serverTimestamp(),
          });
          setState(() => _flowComplete = true);
        }
      }
      // 3. Eğer takip akışı tamamlandıysa, klasik ChatGPT sohbetine dön
      else {
        final historySnapshot = await _messagesRef.orderBy('sentAt').get();
        final openAIHistory =
            historySnapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'role':
                    data['senderId'] == _currentUser.id ? 'user' : 'assistant',
                'content': data['text'] ?? '',
              };
            }).toList();

        final request = ChatCompleteText(
          model: Gpt4oMiniChatModel(),
          messages: openAIHistory,
          maxToken: 1000,
        );

        final resp = await _openAI.onChatCompletion(request: request);
        final aiContent = resp?.choices.first.message?.content.trim() ?? '';
        if (aiContent.isNotEmpty) {
          await _messagesRef.add({
            'text': aiContent,
            'senderId': _gptChatUser.id,
            'sentAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('❌ OpenAI error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: CustomErrorWidget(
              message: 'OpenAI ile iletişim kurulamadı',
              onRetry: () => _onSendMessage(userMsg),
            ),
          ),
        );
      }
    }

    setState(() => _gptState = 'Çevrimiçi');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'DoktorumOnline AI'),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _messagesRef.orderBy('sentAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages =
              snapshot.data?.docs
                  .map((doc) {
                    final data = doc.data();
                    return ChatMessage(
                      text: data['text'] ?? '',
                      user:
                          data['senderId'] == _currentUser.id
                              ? _currentUser
                              : _gptChatUser,
                      createdAt:
                          (data['sentAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                    );
                  })
                  .toList()
                  .reversed
                  .toList() ??
              [];

          return DashChat(
            currentUser: _currentUser,
            onSend: (ChatMessage message) {
              _onSendMessage(message);
            },
            messages: messages,
            messageOptions: MessageOptions(
              showTime: true,
              messageDecorationBuilder: (message, prev, next) {
                final isMe = message.user.id == _currentUser.id;
                return BoxDecoration(
                  color: isMe ? Colors.blue : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                );
              },
              messageTextBuilder: (message, prev, next) {
                return Text(
                  message.text,
                  style: TextStyle(
                    color:
                        message.user.id == _currentUser.id
                            ? Colors.white
                            : Colors.black87,
                    fontSize: 15,
                  ),
                );
              },
              avatarBuilder: (user, onTap, onLongPress) {
                return CircleAvatar(
                  backgroundColor:
                      user.id == _currentUser.id
                          ? Colors.blue.shade100
                          : Colors.teal.shade100,
                  child: Icon(
                    user.id == _currentUser.id
                        ? Icons.person
                        : Icons.medical_services,
                    color:
                        user.id == _currentUser.id ? Colors.blue : Colors.teal,
                  ),
                );
              },
            ),
            inputOptions: InputOptions(
              inputTextStyle: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              inputDecoration: InputDecoration(
                hintText: 'Mesajınızı yazın...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
