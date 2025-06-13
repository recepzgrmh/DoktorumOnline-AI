import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FormService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> saveComplaint({
    required Map<String, String> inputs,
    required String complaintId,
  }) async {
    final uid = _auth.currentUser!.uid;
    final complaintDoc = _firestore
        .collection('users')
        .doc(uid)
        .collection('complaints')
        .doc(complaintId);

    await complaintDoc.set({
      'boy': inputs['Boy'],
      'yas': inputs['Yaş'],
      'kilo': inputs['Kilo'],
      'sikayet': inputs['Şikayet'],
      'sure': inputs['Şikayet Süresi'],
      'ilac': inputs['Mevcut İlaçlar'],
      'Kronik Rahatsızlık': inputs['Kronik Rahatsızlık'],
      'cinsiyet': inputs['Cinsiyet'],
      'kan_grubu': inputs['Kan Grubu'],
      'lastAnalyzed': FieldValue.serverTimestamp(),
    });

    return complaintId;
  }

  Future<void> saveMessage({
    required String complaintId,
    required String text,
    required String senderId,
  }) async {
    final uid = _auth.currentUser!.uid;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('complaints')
        .doc(complaintId)
        .collection('messages')
        .add({
          'text': text,
          'senderId': senderId,
          'sentAt': FieldValue.serverTimestamp(),
        });
  }

  Future<List<Map<String, dynamic>>> getMessageHistory(
    String complaintId,
  ) async {
    final uid = _auth.currentUser!.uid;
    final snapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('complaints')
            .doc(complaintId)
            .collection('messages')
            .orderBy('sentAt')
            .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
