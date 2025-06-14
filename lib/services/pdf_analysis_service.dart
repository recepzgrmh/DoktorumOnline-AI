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
  }

  Stream<List<PdfAnalysis>> getAnalyses() {
    final uid = _auth.currentUser!.uid;
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
