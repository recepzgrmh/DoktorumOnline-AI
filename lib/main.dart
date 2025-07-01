import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:login_page/theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:login_page/wrapper.dart';
import 'package:login_page/screens/opening.dart';
import 'package:firebase_auth/firebase_auth.dart';

// GetX için navigator anahtarını tanımla
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "assets/.env");
    print("📌 `.env` dosyası başarıyla yüklendi!");
    print("📌 FIREBASE_API_KEY: ${dotenv.env['FIREBASE_API_KEY'] ?? 'YOK!'}");
  } catch (e) {
    print("🚨 `.env` dosyası yüklenemedi! Hata: $e");
  }

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Firebase Auth ayarlarını yapılandır
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

      // Mevcut oturumu kontrol et
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Token'ı yenile
        await currentUser.getIdToken(true);
        print("🔥 Mevcut kullanıcı oturumu bulundu: ${currentUser.email}");
      }

      print("🔥 Firebase Başlatıldı!");
    } else {
      print("Firebase zaten başlatılmış.");
    }
  } catch (e) {
    print("🚨 Firebase Başlatma Hatası: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey, // GetX navigator anahtarını kullan
      title: 'DoktorumOnline AI',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const Wrapper(), // Opening yerine Wrapper'ı kullan
    );
  }
}
