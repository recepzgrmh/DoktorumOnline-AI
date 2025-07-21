import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pdf_analysis.dart';

class PdfAnalysisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> saveAnalysis({
    required String fileName,
    required Map<String, String> analysis,
  }) async {
    try {
      final uid = _auth.currentUser!.uid;
      final docRef =
          _firestore
              .collection('users')
              .doc(uid)
              .collection('pdf_analyses')
              .doc();

      final pdfAnalysis = PdfAnalysis(
        id: docRef.id,
        fileName: fileName,
        analysis: analysis,
        createdAt: DateTime.now(),
        userId: uid,
      );

      await docRef.set(pdfAnalysis.toMap());

      return docRef.id;
    } catch (e) {
      rethrow; // Hatayı yukarıya tekrar fırlat
    }
  }

  Stream<List<PdfAnalysis>> getAnalyses() {
    final user = _auth.currentUser;
    if (user == null) {
      // Kullanıcı giriş yapmamışsa boş bir stream döndür.

      return Stream.value([]);
    }

    final uid = user.uid;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('pdf_analyses')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PdfAnalysis.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> deleteAnalysis(String analysisId) async {
    final uid = _auth.currentUser!.uid;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('pdf_analyses')
        .doc(analysisId)
        .delete();
  }
}
