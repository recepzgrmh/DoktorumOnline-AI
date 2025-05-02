import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:login_page/theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:login_page/wrapper.dart';

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
      title: 'Login Page',
      /*theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ),
*/
      theme: AppTheme.lightTheme,

      home: const Wrapper(),
    );
  }
}
