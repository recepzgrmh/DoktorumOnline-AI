import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:login_page/screens/chat_history_detail_screen.dart';
import 'package:login_page/services/tutorial_service.dart';
import 'package:login_page/widgets/coachmark_desc.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class OldChatScreen extends StatefulWidget {
  final String userId;
  const OldChatScreen({super.key, required this.userId});

  @override
  OldChatScreenState createState() => OldChatScreenState();
}

class OldChatScreenState extends State<OldChatScreen> {
  final List<Color> _avatarPalette = [
    Colors.red,
    Colors.redAccent,
    Colors.pink,
    Colors.pinkAccent,
    Colors.purple,
    Colors.deepPurple,
    Colors.deepPurpleAccent,
    Colors.indigo,
    Colors.indigoAccent,
    Colors.blue,
    Colors.lightBlue,
    Colors.lightBlueAccent,
    Colors.blueAccent,
    Colors.cyan,
    Colors.cyanAccent,
    Colors.teal,
    Colors.tealAccent,
    Colors.green,
    Colors.lightGreen,
    Colors.greenAccent,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.amberAccent,
    Colors.orange,
    Colors.deepOrange,
    Colors.deepOrangeAccent,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  TutorialCoachMark? tutorialCoachMark;
  List<TargetFocus> targets = [];
  final GlobalKey _firstChatItemKey = GlobalKey();

  @override
  void dispose() {
    tutorialCoachMark?.finish();
    super.dispose();
  }

  void showTutorial() {
    _initTargets();
    if (targets.isEmpty || !mounted) return;
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      onFinish: () => TutorialService.markTutorialAsSeen('oldChats'),
      onSkip: () {
        TutorialService.markTutorialAsSeen('oldChats');
        return true;
      },
    )..show(context: context, rootOverlay: true);
  }

  void _initTargets() {
    targets.clear();
    if (_firstChatItemKey.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "First Chat Item",
          keyTarget: _firstChatItemKey,
          shape: ShapeLightFocus.RRect,
          radius: 16,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return CoachmarkDesc(
                  text:
                      'Geçmiş bir görüşmenizi görüntülemek için buraya dokunun.',
                  next: 'Anladım',
                  skip: 'Geç',
                  onNext: controller.skip,
                  onSkip: controller.skip,
                );
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaintsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('complaints');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            complaintsRef.orderBy('lastAnalyzed', descending: true).snapshots(),
        builder: (context, chatSnapshots) {
          if (chatSnapshots.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            );
          }
          if (chatSnapshots.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    "Bir hata oluştu",
                    style: TextStyle(color: Colors.red[300], fontSize: 16),
                  ),
                ],
              ),
            );
          }
          if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz Mesaj Yok',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final loadMessages = chatSnapshots.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: loadMessages.length,
            itemBuilder: (context, index) {
              final complaintDoc = loadMessages[index];
              final color =
                  _avatarPalette[complaintDoc.id.hashCode %
                      _avatarPalette.length];

              return Padding(
                key: index == 0 ? _firstChatItemKey : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ChatHistoryDetailScreen(
                                userId: widget.userId,
                                complaintId: complaintDoc.id,
                              ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.medical_services,
                                color: color,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  complaintDoc['sikayet'] ?? '',
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>
                                >(
                                  stream:
                                      complaintsRef
                                          .doc(complaintDoc.id)
                                          .collection('messages')
                                          .orderBy('sentAt', descending: true)
                                          .limit(1)
                                          .snapshots(),
                                  builder: (context, snap) {
                                    if (snap.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text(
                                        'Yükleniyor…',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 13,
                                        ),
                                      );
                                    }
                                    if (!snap.hasData ||
                                        snap.data!.docs.isEmpty) {
                                      return Text(
                                        'Henüz Mesaj Yok',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 13,
                                        ),
                                      );
                                    }
                                    final msg = snap.data!.docs.first.data();
                                    final text = msg['text'] ?? '';
                                    return Text(
                                      text,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(
                                (complaintDoc['lastAnalyzed'] as Timestamp)
                                    .toDate(),
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
