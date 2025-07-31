import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:login_page/services/firebase_analytics.dart';
import 'package:login_page/services/notification_service.dart';
import 'package:login_page/theme/app_theme.dart';
import 'firebase_options.dart';
import 'package:login_page/wrapper.dart';
import "package:easy_localization/easy_localization.dart";
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();

  print("[DEBUG] main başladı");
  try {
    await dotenv.load(fileName: "assets/.env");
    print("[DEBUG] .env yüklendi");

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("[DEBUG] Firebase başlatıldı");

      print("[DEBUG] Notification Service başlatıldı");

      // Firebase Auth ayarlarını yapılandır
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      print("[DEBUG] Firebase Auth persistence ayarlandı");

      // Mevcut oturumu kontrol et
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Token'ı yenile
        await currentUser.getIdToken(true);

        print("[DEBUG] Kullanıcı token yenilendi");
      }
    }
  } catch (e, s) {
    print('[ERROR] main() içinde hata:');
    print(e);
    print(s);
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ar'),
        Locale('de'),
        Locale('el'),
        Locale('en'),
        Locale('es'),
        Locale('fr', 'FR'),
        Locale('hi'),
        Locale('it'),
        Locale('ja'),
        Locale('ko'),
        Locale('pt', 'PT'),
        Locale('ru'),
        Locale('tr'),
        Locale('zh', 'CN'),
      ],
      fallbackLocale: const Locale('en'),
      path: 'assets/lang',
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,

      locale: context.locale,

      title: 'DoktorumOnline AI',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const Wrapper(),
      navigatorObservers: [AnalyticsService.instance.getAnalyticsObserver()],
    );
  }
}
