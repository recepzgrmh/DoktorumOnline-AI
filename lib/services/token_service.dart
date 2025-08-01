import 'package:cloud_firestore/cloud_firestore.dart';

class TokenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logTokenUsage({
    required String functionName,
    required String model,
    required int promptTokens,
    required int completionTokens,
    required int totalTokens,
    required String? userEmail,
    required String? userId,
  }) async {
    try {
      await _firestore
          .collection('token_logs')
          .doc(userEmail)
          .collection('usage_logs')
          .add({
            'functionName': functionName,
            'model': model,
            'promptTokens': promptTokens,
            'completionTokens': completionTokens,
            'totalTokens': totalTokens,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Firebase token loglama hatası: $e');
    }
  }
}
