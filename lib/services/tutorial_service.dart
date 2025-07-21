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

  // Mevcut kullanıcının kimliğini alır.
  static String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

  // Çekmece (drawer) eğitimi için kullanıcıya özel bir anahtar oluşturur.
  static String get _drawerKeyForUser => '${_tutorialKeys['drawer']}_$_uid';

  /// GÜNCELLENDİ: Tüm eğitimlerin "görüldü" durumunu sıfırlar.
  /// Bu fonksiyon, bilinen tüm eğitim anahtarlarını dolaşarak temizler.
  static Future<void> resetAllTutorials() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint("Tüm eğitimler sıfırlanıyor...");

    // _tutorialKeys haritasındaki her bir anahtar için SharedPreferences'tan kaydı siler.
    for (var key in _tutorialKeys.keys) {
      String prefKey;
      if (key == 'drawer') {
        // Drawer için kullanıcıya özel anahtarı kullanır.
        prefKey = _drawerKeyForUser;
      } else {
        prefKey = _tutorialKeys[key]!;
      }
      // Anahtarın mevcut olup olmadığını kontrol edip siler.
      if (prefs.containsKey(prefKey)) {
        await prefs.remove(prefKey);
        debugPrint("'$prefKey' anahtarı sıfırlandı.");
      }
    }

    debugPrint("Tüm eğitimler başarıyla sıfırlandı.");
  }

  /// Belirtilen eğitimin daha önce görülüp görülmediğini kontrol eder.
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
      return true; // Anahtar yoksa, görülmüş varsay.
    }

    // Anahtarın değerini oku, eğer yoksa 'false' (görülmemiş) döner.
    return prefs.getBool(key) ?? false;
  }

  /// Belirtilen eğitimi "görüldü" olarak işaretler.
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
