import 'package:flutter/material.dart';

class ChatItem {
  final String avatarPath = "assets/images/avatar.png";
  final String name;
  final String message;
  final String time;

  ChatItem({required this.name, required this.message, required this.time});
}

class OldChatScreen extends StatefulWidget {
  const OldChatScreen({super.key});

  @override
  State<OldChatScreen> createState() => _OldChatScreenState();
}

class _OldChatScreenState extends State<OldChatScreen> {
  final List<ChatItem> _chats = [
    ChatItem(
      name: 'Sırt Ağrısı',
      message: 'lorem ipsum sit amet',
      time: '13:35',
    ),
    ChatItem(
      name: 'Bacaktaki Morarma',
      message: 'lorem ipsum sit amet',
      time: '11:20',
    ),
    ChatItem(
      name: 'Sırt Ağrısı',
      message: 'lorem ipsum sit amet',
      time: '10:35',
    ),
    ChatItem(
      name: 'Sırt Ağrısı',
      message: 'lorem ipsum sit amet',
      time: '10:35',
    ),
    ChatItem(
      name: 'Sırt Ağrısı',
      message: 'lorem ipsum sit amet',
      time: '10:35',
    ),
    ChatItem(
      name: 'Sırt Ağrısı',
      message: 'lorem ipsum sit amet',
      time: '10:35',
    ),
    ChatItem(
      name: 'Sırt Ağrısı',
      message: 'lorem ipsum sit amet',
      time: '10:35',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.teal,
        title: const Text(
          'Chat History',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage(chat.avatarPath),
              ),
              title: Text(
                chat.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(chat.message, maxLines: 1),
              trailing: Text(
                chat.time,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}
