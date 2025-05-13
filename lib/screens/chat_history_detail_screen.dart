import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:login_page/widgets/my_drawer.dart';

class ChatHistoryDetailScreen extends StatelessWidget {
  final String userId;
  final String complaintId;

  const ChatHistoryDetailScreen({
    Key? key,
    required this.userId,
    required this.complaintId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'DoktorumOnline AI',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      drawer: const MyDrawer(),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('complaints')
                .doc(complaintId)
                .collection('messages')
                .orderBy('sentAt')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Henüz Mesaj Yok'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final ts = data['sentAt'];
              final dateText =
                  ts is Timestamp ? ts.toDate().toLocal().toString() : '';
              return ListTile(
                title: Text(data['text'] ?? ''),
                subtitle: Text(
                  dateText,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
