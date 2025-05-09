import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> get chatsStream =>
      _db.collection('users').doc(uid).collection('chats').snapshots();

  final String uid;
  ChatService(this.uid);
}
