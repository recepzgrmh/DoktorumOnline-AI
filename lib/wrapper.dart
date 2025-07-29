import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:login_page/screens/main_navigation_screen.dart';
import 'package:login_page/screens/opening.dart';
import 'package:login_page/screens/auth/verify_account.dart';
import 'package:login_page/services/notification_service.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  void initState() {
    super.initState();
    _checkUserState();
  }

  Future<void> _checkUserState() async {
    await NotificationService().initNotification();
    try {
      print('[DEBUG] _checkUserState başladı');
      // Mevcut kullanıcıyı kontrol et
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        print('[DEBUG] Kullanıcı bulundu: ${user.email}');
        // Kullanıcı oturumu varsa, token'ı yenile
        await user.getIdToken(true);
        print('[DEBUG] Kullanıcı token yenilendi');

        if (!user.emailVerified) {
          await user.reload();
          print('[DEBUG] Kullanıcı email doğrulanmamış, reload edildi');
          setState(() {});
        }
      } else {
        print('[DEBUG] Kullanıcı yok');
      }
    } catch (e, s) {
      print('[ERROR] _checkUserState içinde hata:');
      print(e);
      print(s);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[DEBUG] Wrapper build başladı');
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          print(
            '[DEBUG] StreamBuilder çalıştı, connectionState: ${snapshot.connectionState}',
          );
          // Yükleme durumu
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('[DEBUG] StreamBuilder: waiting');
            return const Center(child: CircularProgressIndicator());
          }

          // Hata durumu
          if (snapshot.hasError) {
            print('[ERROR] StreamBuilder: snapshot.hasError');
            return const Opening();
          }

          // Kullanıcı durumu
          if (snapshot.hasData) {
            print('[DEBUG] StreamBuilder: snapshot.hasData');
            User? user = snapshot.data;
            if (user != null) {
              print(
                '[DEBUG] StreamBuilder: user var, emailVerified: ${user.emailVerified}',
              );
              if (user.emailVerified) {
                print('[DEBUG] StreamBuilder: MainScreen() döndürülüyor');
                return MainScreen();
              } else {
                print('[DEBUG] StreamBuilder: VerifyAccount() döndürülüyor');
                return const VerifyAccount();
              }
            }
          }

          // Kullanıcı yoksa giriş ekranına yönlendir
          print('[DEBUG] StreamBuilder: kullanıcı yok, Opening() döndürülüyor');
          return const Opening();
        },
      ),
    );
  }
}
