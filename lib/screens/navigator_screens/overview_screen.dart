// lib/screens/overview_screen.dart
//
// Modernize edilmiş UI + hatasız derleme
//
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:login_page/screens/navigator_screens/home_screen.dart';
import 'package:login_page/services/openai_service.dart';
import 'package:login_page/services/form_service.dart';
import 'package:login_page/widgets/custom_page_route.dart';
import 'package:login_page/widgets/error_widget.dart';
import 'package:login_page/widgets/custom_appbar.dart';

class OverviewScreen extends StatefulWidget {
  final String uid;
  final String complaintId;
  final Map<String, String> inputs;
  final List<String> questions;
  final Map<String, String>? fileAnalysis;

  const OverviewScreen({
    super.key,
    required this.uid,
    required this.complaintId,
    required this.inputs,
    required this.questions,
    this.fileAnalysis,
  });

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen>
    with TickerProviderStateMixin {
  int _offTopicCounter = 0; // Konu dışı soru sayacı
  bool _chatLocked = false; // Sohbetin kilitlenip kilitlenmediğini tutar

  late final OpenAI _openAI;
  final OpenAIService _service = OpenAIService();
  final FormService _formService = FormService();
  late final String _apiKey;

  final ChatUser _currentUser = ChatUser(id: '1', firstName: 'Sen');
  final ChatUser _gptChatUser = ChatUser(id: '2', firstName: 'Sağlık Asistanı');

  late final CollectionReference<Map<String, dynamic>> _messagesRef;

  // Soru–cevap akışı
  int _currentQIndex = 0;
  final List<String> _answers = [];
  bool _flowComplete = false;

  String _gptState = 'Çevrimiçi';

  // Animation controllers
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressController.forward();
    _pulseController.repeat(reverse: true);

    _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (_apiKey.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('api_key_missing'.tr())),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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

    // Eğer sadece tek mesaj varsa (değerlendirme mesajı), flow'u tamamla
    if (widget.questions.length == 1) {
      _flowComplete = true;
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // Kalan soru sayısını hesapla
  int get _remainingQuestions =>
      _flowComplete ? 0 : widget.questions.length - _currentQIndex;

  // Progress yüzdesini hesapla
  double get _progressPercentage =>
      widget.questions.isEmpty ? 1.0 : _currentQIndex / widget.questions.length;

  // Progress indicator widget'ı
  Widget _buildProgressIndicator() {
    if (_flowComplete) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00C853), Color(0xFF4CAF50), Color(0xFF66BB6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'progress_completed_title'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'progress_completed_desc'.tr(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.medical_services,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'diagnosis_process'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'remaining_questions'.tr(args: ['$_remainingQuestions']),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progressPercentage * _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4F8AF7),
                          Color(0xFF6DB7FF),
                          Color(0xFF8BC34A),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'questions_done'.tr(
                  args: [
                    _currentQIndex.toString(),
                    widget.questions.length.toString(),
                  ],
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'percent_done'.tr(
                  args: [((_progressPercentage * 100).toStringAsFixed(0))],
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onSendMessage(ChatMessage userMsg) async {
    if (_chatLocked) return;
    setState(() => _gptState = '...yazıyor');

    try {
      // Kullanıcı mesajını kaydet
      await _messagesRef.add({
        'text': userMsg.text,
        'senderId': _currentUser.id,
        'sentAt': FieldValue.serverTimestamp(),
      });

      // İlk tanısal soru–cevap akışı
      if (!_flowComplete &&
          widget.questions.length > 1 &&
          _currentQIndex < widget.questions.length) {
        _answers.add(userMsg.text.trim());

        if (_currentQIndex + 1 < widget.questions.length) {
          // Sıradaki soru
          final nextQ = widget.questions[_currentQIndex + 1];
          await _messagesRef.add({
            'text': nextQ,
            'senderId': _gptChatUser.id,
            'sentAt': FieldValue.serverTimestamp(),
          });
          setState(() => _currentQIndex++);
        } else {
          // Nihai rapor
          final complaintData = await _formService.getComplaintWithProfile(
            widget.complaintId,
          );
          final profileData = {
            'Boy': complaintData['boy']?.toString() ?? '',
            'Yaş': complaintData['yas']?.toString() ?? '',
            'Kilo': complaintData['kilo']?.toString() ?? '',
            'Cinsiyet': complaintData['cinsiyet']?.toString() ?? '',
            'Kan Grubu': complaintData['kan_grubu']?.toString() ?? '',
            'Kronik Rahatsızlık':
                complaintData['kronik_rahatsizlik']?.toString() ?? '',
          };
          final complaintInfo = {
            'Şikayet': complaintData['sikayet']?.toString() ?? '',
            'Şikayet Süresi': complaintData['sure']?.toString() ?? '',
            'Mevcut İlaçlar': complaintData['ilac']?.toString() ?? '',
          };

          final report = await _service.getFinalEvaluation(
            profileData,
            complaintInfo,
            _answers,

            widget.fileAnalysis,
          );
          await _messagesRef.add({
            'text': report,
            'senderId': _gptChatUser.id,
            'sentAt': FieldValue.serverTimestamp(),
          });
          setState(() => _flowComplete = true);
        }
      } else {
        // Normal ChatGPT modu - soru-cevap akışı tamamlandı veya hiç soru yok
        final historySnapshot = await _messagesRef.orderBy('sentAt').get();

        // API'ye gönderilecek mesaj listesini sistem talimatıyla başlat
        final List<Map<String, dynamic>> messagesForApi = [
          {'role': 'system', 'content': 'ai_system_prompt_medical'.tr()},
          // Mevcut sohbet geçmişini ekle
          ...historySnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'role':
                  data['senderId'] == _currentUser.id ? 'user' : 'assistant',
              'content': data['text'] ?? '',
            };
          }).toList(),
        ];

        final request = ChatCompleteText(
          model: Gpt4oMiniChatModel(),
          messages: messagesForApi,
          maxToken: 1000,
        );

        final resp = await _openAI.onChatCompletion(request: request);
        final aiContent = resp?.choices.first.message?.content.trim() ?? '';
        if (aiContent.isNotEmpty) {
          final String offTopicKeyword = 'ai_off_topic_rejection_keyword'.tr();

          bool isOffTopic = aiContent.contains(offTopicKeyword);
          if (isOffTopic) {
            _offTopicCounter++;
            print("bağlam dışı soru soruldu $_offTopicCounter / 2");
          }

          await _messagesRef.add({
            'text': aiContent,
            'senderId': _gptChatUser.id,
            'sentAt': FieldValue.serverTimestamp(),
          });

          if (_offTopicCounter > 2) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                final theme = Theme.of(context);

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),

                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.primaryColor,
                        size: 48.0,
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        'chat_finished'.tr(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    'ai_chat_finished'.tr(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  actionsAlignment: MainAxisAlignment.center,
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),

                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          CustomPageRoute(child: HomeScreen()),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: Text(
                        'turn_back_home_page'.tr(),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                );
              },
            );
            debugPrint(
              "Bağlam dışı soru adedine ulaşıldı. Sohbet kilitleniyor.",
            );

            setState(() {
              _chatLocked = true;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('❌ OpenAI error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: CustomErrorWidget(
              message: 'openai_error'.tr(),
              onRetry: () => _onSendMessage(userMsg),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
    if (!_chatLocked) {
      setState(() => _gptState = 'Çevrimiçi');
    } else {
      // Sohbet kilitlendiyse, yazıyor durumunu temizle ve son durumu ayarla
      setState(() => _gptState = 'Analiz Tamamlandı');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(title: 'overview_title'.tr()),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white, Colors.grey.shade50],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            // Chat interface
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _messagesRef.orderBy('sentAt').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red.shade400,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'error'.tr(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue.shade600,
                                  ),
                                  strokeWidth: 3,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'loading_messages'.tr(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
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
                                      (data['sentAt'] as Timestamp?)
                                          ?.toDate() ??
                                      DateTime.now(),
                                );
                              })
                              .toList()
                              .reversed
                              .toList() ??
                          [];

                      return DashChat(
                        currentUser: _currentUser,
                        typingUsers:
                            _gptState.startsWith('...yaz')
                                ? [_gptChatUser]
                                : [],
                        messages: messages,
                        onSend: _onSendMessage,
                        messageOptions: MessageOptions(
                          // 🌟 GÖRSEL AYARLAR
                          showCurrentUserAvatar: true,
                          showOtherUsersAvatar: true,
                          showTime: true,
                          avatarBuilder: (user, onTap, onLongPress) {
                            final isMe = user.id == _currentUser.id;

                            return GestureDetector(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors:
                                        isMe
                                            ? [
                                              Colors.blue.shade400,
                                              Colors.blue.shade600,
                                            ]
                                            : [
                                              Colors.green.shade400,
                                              Colors.green.shade600,
                                            ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isMe ? Colors.blue : Colors.green)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.transparent,
                                  child: Icon(
                                    isMe
                                        ? Icons.person
                                        : Icons.medical_services,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            );
                          },

                          messageDecorationBuilder: (message, prev, next) {
                            final isMe = message.user.id == _currentUser.id;
                            return BoxDecoration(
                              gradient:
                                  isMe
                                      ? const LinearGradient(
                                        colors: [
                                          Color(0xFF4F8AF7),
                                          Color(0xFF6DB7FF),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                      : LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Colors.grey.shade50,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(isMe ? 20 : 6),
                                bottomRight: Radius.circular(isMe ? 6 : 20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                              border:
                                  isMe
                                      ? null
                                      : Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1,
                                      ),
                            );
                          },
                          messagePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          messageTextBuilder: (message, prev, next) {
                            final isMe = message.user.id == _currentUser.id;
                            return Text(
                              message.text,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            );
                          },
                          messageTimeBuilder: (message, isOwnMessage) {
                            final time = DateFormat(
                              'HH:mm',
                            ).format(message.createdAt);
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                time,
                                style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      isOwnMessage
                                          ? Colors.white70
                                          : Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                        scrollToBottomOptions: ScrollToBottomOptions(),
                        inputOptions: InputOptions(
                          inputDisabled: _chatLocked,
                          inputDecoration: InputDecoration(
                            hintText:
                                _chatLocked
                                    ? 'analysis_complete'.tr()
                                    // Kilitliyken gösterilecek yazı
                                    : 'write_message_hint'.tr(), // Normal yazı
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 16,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(
                                color: Colors.blue.shade400,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.grey.shade400,
                              size: 20,
                            ),
                          ),
                          inputTextStyle: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          sendButtonBuilder: (onSend) {
                            return Container(
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors:
                                      _chatLocked
                                          ? [
                                            Colors.grey.shade400,
                                            Colors.grey.shade600,
                                          ]
                                          : [
                                            Colors.blue.shade400,
                                            Colors.blue.shade600,
                                          ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        _chatLocked
                                            ? Colors.grey.withOpacity(0.3)
                                            : Colors.blue.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: _chatLocked ? null : onSend,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
