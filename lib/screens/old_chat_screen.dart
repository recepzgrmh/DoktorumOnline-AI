import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:login_page/widgets/my_drawer.dart';

class OldChatScreen extends StatefulWidget {
  final String userId;
  final String complaintId;

  const OldChatScreen({
    super.key,
    required this.userId,
    required this.complaintId,
  });

  @override
  State<OldChatScreen> createState() => _OldChatScreenState();
}

class _OldChatScreenState extends State<OldChatScreen> {
  @override
  Widget build(BuildContext context) {
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: StreamBuilder(
                    stream:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.userId)
                            .collection('complaints')
                            .doc(widget.complaintId)
                            .collection('messages')
                            .orderBy('sendAt', descending: false)
                            .snapshots(),
                    builder: (context, chatSnapshots) {
                      if (chatSnapshots.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!chatSnapshots.hasData ||
                          chatSnapshots.data!.docs.isEmpty) {
                        return Text('Henüz Mesaj Yok');
                      }
                      if (chatSnapshots.hasError) {
                        return Text("hataaa");
                      }

                      return Text('data');
                    },
                  ),
                  trailing: Text('data'),
                  onTap: () {},
                ),
              );
            },
          );
        },
      ),
    );
  }
}
