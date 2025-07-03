import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const Map<String, String> _tutorialKeys = {
    'home': 'hasSeenHomeTutorial',

    'complaint': 'hasSeenComplaintTutorial',
    'pdfAnalysis': 'hasSeenPdfAnalysisTutorial',
    'drawer': 'hasSeenDrawerTutorial',
  };

  /// Tüm tutorial'ları sıfırlar
  static Future<void> resetAllTutorials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Tüm tutorial anahtarlarını false yap
      for (String key in _tutorialKeys.values) {
        await prefs.setBool(key, false);
      }

      // Drawer tutorial için kullanıcıya özel anahtarları da sıfırla
      // Bu anahtar formatı: hasSeenDrawerTutorial_${userId}
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('hasSeenDrawerTutorial_')) {
          await prefs.setBool(key, false);
        }
      }
    } catch (e) {
      print('Tutorial sıfırlama hatası: $e');
    }
  }

  /// Belirli bir tutorial'ı sıfırlar
  static Future<void> resetTutorial(String tutorialName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _tutorialKeys[tutorialName];

      if (key != null) {
        await prefs.setBool(key, false);
      }
    } catch (e) {
      print('Tutorial sıfırlama hatası: $e');
    }
  }

  /// Belirli bir tutorial'ın görülüp görülmediğini kontrol eder
  static Future<bool> hasSeenTutorial(String tutorialName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _tutorialKeys[tutorialName];

      if (key != null) {
        return prefs.getBool(key) ?? false;
      }
      return false;
    } catch (e) {
      print('Tutorial kontrol hatası: $e');
      return false;
    }
  }

  /// Belirli bir tutorial'ı görüldü olarak işaretler
  static Future<void> markTutorialAsSeen(String tutorialName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _tutorialKeys[tutorialName];

      if (key != null) {
        await prefs.setBool(key, true);
      }
    } catch (e) {
      print('Tutorial işaretleme hatası: $e');
    }
  }

  /// Mevcut tüm tutorial anahtarlarını döndürür
  static Map<String, String> get tutorialKeys =>
      Map.unmodifiable(_tutorialKeys);
}
