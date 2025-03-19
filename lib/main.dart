import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:login_page/wrapper.dart';
import 'package:get/get.dart';
import 'firebase_options.dart'; // Firebase yapılandırmasını içe aktar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env dosyasını yükle
  await dotenv.load(fileName: ".env");

  try {
    await Firebase.initializeApp(
      options:
          DefaultFirebaseOptions
              .currentPlatform, // Güvenli Firebase yapılandırması
    );
    print("🔥 Firebase Başlatıldı!"); // Konsola başarı mesajı
  } catch (e) {
    print("🚨 Firebase Başlatma Hatası: $e"); // Hata mesajını yazdır
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Login Page',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
        ),
      ),
      home: const Wrapper(),
    );
  }
}
