import 'package:flutter/material.dart';

class AppConstants {
  // Colors
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Colors.teal;
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.black87;
  static const Color errorColor = Colors.redAccent;

  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textColor,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textColor,
  );

  static const TextStyle bodyStyle = TextStyle(fontSize: 14, color: textColor);

  // Dimensions
  static const double defaultPadding = 20.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultIconSize = 24.0;

  // Messages
  static const String loadingMessage = "Şikayetiniz işleniyor...";
  static const String errorMessage =
      "Bir hata oluştu. Lütfen tekrar deneyiniz.";
  static const String successMessage = "İşlem başarıyla tamamlandı.";
  static const String formInfoMessage =
      'Lütfen aşağıdaki bilgileri doldurunuz. Bu bilgiler doktorunuzun size daha iyi yardımcı olmasını sağlayacaktır.';

  // Form Labels
  static const String heightLabel = 'Boy (cm)';
  static const String ageLabel = 'Yaş';
  static const String weightLabel = 'Kilo (kg)';
  static const String genderLabel = 'Cinsiyet';
  static const String bloodTypeLabel = 'Kan Grubu';
  static const String complaintLabel = 'Şikayetiniz';
  static const String durationLabel = 'Şikayet Süresi';
  static const String medicationLabel = 'Mevcut İlaçlar';
  static const String chronicDiseaseLabel = 'Kronik Rahatsızlık';

  // Button Labels
  static const String uploadFileLabel = 'Dosya Yükle';
  static const String startComplaintLabel = 'Şikayeti Başlat';
  static const String analyzeLabel = 'Analiz Et';
}
