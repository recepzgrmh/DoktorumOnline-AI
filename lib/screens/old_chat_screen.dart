import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:login_page/screens/chat_history_detail_screen.dart';
import 'package:login_page/widgets/my_drawer.dart';

class OldChatScreen extends StatefulWidget {
  final String userId;

  const OldChatScreen({super.key, required this.userId});

  @override
  State<OldChatScreen> createState() => _OldChatScreenState();
}

class _OldChatScreenState extends State<OldChatScreen> {
  @override
  Widget build(BuildContext context) {
    final complaintsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('complaints');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'DoktorumOnline AI',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      drawer: MyDrawer(),
      body: StreamBuilder(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .collection('complaints')
                .orderBy('lastAnalyzed', descending: true)
                .snapshots(),
        builder: (context, chatSnapshots) {
          if (chatSnapshots.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
            return Center(child: Text('Henüz Mesaj Yok'));
          }
          if (chatSnapshots.hasError) {
            return Center(child: Text("hataaa"));
          }

          final loadMessages = chatSnapshots.data!.docs;

          return ListView.builder(
            itemCount: loadMessages.length,
            itemBuilder: (context, index) {
              final complaintDoc = loadMessages[index];
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage('assets/images/avatar.png'),
                  ),
                  title: Text(
                    complaintDoc['sikayet'],
                    maxLines: 1,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.userId)
                            .collection('complaints')
                            .doc(complaintDoc.id)
                            .collection('messages')
                            .orderBy('sentAt', descending: true)
                            .limit(1)
                            .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Text(
                          'Yükleniyor…',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        );
                      }
                      if (!snap.hasData || snap.data!.docs.isEmpty) {
                        return const Text(
                          'Henüz Mesaj Yok',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        );
                      }
                      final msg = snap.data!.docs.first.data();
                      final text = msg['text'] ?? '';
                      return Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                  trailing: Text(DateTime.now().toString().split(' ')[0]),

                  // loadMessages[index][widget.complaintId]['text'],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ChatHistoryDetailScreen(
                              userId: widget.userId,
                              complaintId: complaintDoc.id,
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
