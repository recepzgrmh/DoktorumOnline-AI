import 'package:cloud_firestore/cloud_firestore.dart';

class PdfAnalysis {
  final String id;
  final String fileName;
  final Map<String, String> analysis;
  final DateTime createdAt;
  final String userId;

  PdfAnalysis({
    required this.id,
    required this.fileName,
    required this.analysis,
    required this.createdAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'analysis': analysis,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
    };
  }

  factory PdfAnalysis.fromMap(String id, Map<String, dynamic> map) {
    final rawAnalysis = map['analysis'];
    Map<String, String> analysisMap;
    if (rawAnalysis is String) {
      // Eski kayıtlar için tek başlık altında göster
      analysisMap = {'Analiz': rawAnalysis};
    } else if (rawAnalysis is Map) {
      analysisMap = Map<String, String>.from(rawAnalysis);
    } else {
      analysisMap = {'Analiz': 'Veri okunamadı'};
    }
    return PdfAnalysis(
      id: id,
      fileName: map['fileName'] ?? '',
      analysis: analysisMap,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
    );
  }
}
