import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_page/screens/home_Screen.dart';
import 'package:login_page/screens/opening.dart';
import 'package:login_page/screens/auth/verify_account.dart';

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
    try {
      // Mevcut kullanıcıyı kontrol et
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Kullanıcı oturumu varsa, token'ı yenile
        await user.getIdToken(true);

        if (!user.emailVerified) {
          await user.reload();
          setState(() {});
        }
      }
    } catch (e) {
      print("🚨 Kullanıcı durumu kontrol hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Yükleme durumu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Hata durumu
          if (snapshot.hasError) {
            print("🚨 Auth State Error: ${snapshot.error}");
            return const Opening();
          }

          // Kullanıcı durumu
          if (snapshot.hasData) {
            User? user = snapshot.data;
            if (user != null) {
              if (user.emailVerified) {
                return const HomeScreen();
              } else {
                return const VerifyAccount();
              }
            }
          }

          // Kullanıcı yoksa giriş ekranına yönlendir
          return const Opening();
        },
      ),
    );
  }
}
