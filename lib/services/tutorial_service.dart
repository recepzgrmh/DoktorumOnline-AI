import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  // Tüm eğitim anahtarları merkezi bir yerde tanımlandı.
  static const Map<String, String> _tutorialKeys = {
    'home': 'hasSeenHomeTutorial',
    'oldChats': 'hasSeenOldChatsTutorial',
    'pdfAnalysis': 'hasSeenPdfAnalysisTutorial',
    'profiles': 'hasSeenProfilesTutorial',
    'drawer': 'hasSeenDrawerTutorial',
  };
  static String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  // Tüm anahtarlar için kullanıcıya özel versiyon
  static String _getKeyForUser(String tutorialName) {
    final baseKey = _tutorialKeys[tutorialName];
    if (baseKey == null) return '';
    return '${baseKey}_$_uid';
  }

  /// GÜNCELLENDİ: Tüm eğitimlerin "görüldü" durumunu sıfırlar.
  /// Bu fonksiyon, bilinen tüm eğitim anahtarlarını dolaşarak temizler.
  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();

    for (var tutorialName in _tutorialKeys.keys) {
      final userKey = _getKeyForUser(tutorialName);
      if (userKey.isNotEmpty && prefs.containsKey(userKey)) {
        await prefs.remove(userKey);
        debugPrint("'$userKey' anahtarı sıfırlandı.");
      }
    }
  }

  /// Belirtilen eğitimin daha önce görülüp görülmediğini kontrol eder.
  static Future<bool> hasSeenTutorial(String tutorialName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKeyForUser(tutorialName);

    if (key.isEmpty) {
      debugPrint("Uyarı: '$tutorialName' için tutorial anahtarı bulunamadı.");
      return true;
    }

    return prefs.getBool(key) ?? false;
  }

  /// Belirtilen eğitimi "görüldü" olarak işaretler.
  static Future<void> markTutorialAsSeen(String tutorialName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKeyForUser(tutorialName);

    if (key.isNotEmpty) {
      await prefs.setBool(key, true);
      debugPrint("'$tutorialName' tutorial'ı görüldü olarak işaretlendi.");
    }
  }
}
