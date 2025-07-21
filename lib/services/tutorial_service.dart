import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  // Tüm ekranlar için tutorial anahtarları
  static const Map<String, String> _tutorialKeys = {
    'home': 'hasSeenHomeTutorial',
    'oldChats': 'hasSeenOldChatsTutorial',
    'pdfAnalysis': 'hasSeenPdfAnalysisTutorial',
    'profiles': 'hasSeenProfilesTutorial',
    'drawer':
        'hasSeenDrawerTutorial', // Bu, kullanıcıya özel anahtar için bir önektir
  };

  // Mevcut kullanıcı kimliğini güvenli bir şekilde alır
  static String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  /// Drawer eğitimi için kullanıcıya özel anahtarı döndürür.
  static String get _drawerKeyForUser => '${_tutorialKeys['drawer']}_$_uid';

  /// Mevcut kullanıcı için tüm eğitimleri sıfırlar.
  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint("Tüm eğitimler sıfırlanıyor...");

    // Tüm genel anahtarları sıfırla
    for (String key in _tutorialKeys.values) {
      if (key != _tutorialKeys['drawer']) {
        await prefs.setBool(key, false);
      }
    }
    // Kullanıcıya özel drawer anahtarını sıfırla
    await prefs.setBool(_drawerKeyForUser, false);

    debugPrint("Tüm eğitimler sıfırlandı.");
  }

  /// Belirli bir eğitimin görülüp görülmediğini kontrol eder.
  static Future<bool> hasSeenTutorial(String tutorialName) async {
    final prefs = await SharedPreferences.getInstance();
    String? key;

    if (tutorialName == 'drawer') {
      key = _drawerKeyForUser;
    } else {
      key = _tutorialKeys[tutorialName];
    }

    if (key == null) {
      debugPrint("Uyarı: '$tutorialName' için eğitim anahtarı bulunamadı.");
      return true; // Hataları önlemek için görüldü varsay
    }

    return prefs.getBool(key) ?? false;
  }

  /// Belirli bir eğitimi görüldü olarak işaretler.
  static Future<void> markTutorialAsSeen(String tutorialName) async {
    final prefs = await SharedPreferences.getInstance();
    String? key;

    if (tutorialName == 'drawer') {
      key = _drawerKeyForUser;
    } else {
      key = _tutorialKeys[tutorialName];
    }

    if (key != null) {
      await prefs.setBool(key, true);
      debugPrint("'$tutorialName' eğitimi görüldü olarak işaretlendi.");
    } else {
      debugPrint(
        "Uyarı: '$tutorialName' için eğitim anahtarı bulunamadı. Görüldü olarak işaretlenemedi.",
      );
    }
  }
}
