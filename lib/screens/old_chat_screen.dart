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
  final List<Color> _avatarPalette = [
    // Reds
    Colors.red,
    Colors.redAccent,
    // Pinks
    Colors.pink,
    Colors.pinkAccent,
    // Purples
    Colors.purple,
    Colors.deepPurple,
    Colors.deepPurpleAccent,
    // Indigos
    Colors.indigo,
    Colors.indigoAccent,
    // Blues
    Colors.blue,
    Colors.lightBlue,
    Colors.lightBlueAccent,
    Colors.blueAccent,
    // Cyans & Teals
    Colors.cyan,
    Colors.cyanAccent,
    Colors.teal,
    Colors.tealAccent,
    // Greens
    Colors.green,
    Colors.lightGreen,
    Colors.greenAccent,
    // Yellows & Ambers
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.amberAccent,
    // Oranges
    Colors.orange,
    Colors.deepOrange,
    Colors.deepOrangeAccent,
    // Neutrals
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            complaintsRef.orderBy('lastAnalyzed', descending: true).snapshots(),
        builder: (context, chatSnapshots) {
          if (chatSnapshots.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (chatSnapshots.hasError) {
            return Center(child: Text("Bir hata oluştu"));
          }
          if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
            return const Center(child: Text('Henüz Mesaj Yok'));
          }

          final loadMessages = chatSnapshots.data!.docs;

          return ListView.builder(
            itemCount: loadMessages.length,
            itemBuilder: (context, index) {
              final complaintDoc = loadMessages[index];

              final color =
                  _avatarPalette[complaintDoc.id.hashCode %
                      _avatarPalette.length];

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/avatar.png',
                        color: color,
                        colorBlendMode: BlendMode.modulate,
                        fit: BoxFit.cover,
                        width: 48,
                        height: 48,
                      ),
                    ),
                  ),
                  title: Text(
                    complaintDoc['sikayet'] ?? '',
                    maxLines: 1,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream:
                        complaintsRef
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
                  trailing: Text(
                    // Tarihi biçimlendirilebilir:
                    DateFormat('yyyy-MM-dd').format(
                      (complaintDoc['lastAnalyzed'] as Timestamp).toDate(),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
