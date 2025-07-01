import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_page/screens/opening.dart';
import 'package:login_page/screens/profiles_screen.dart';
import 'package:login_page/widgets/custom_button.dart';
import 'package:get/get.dart';
import 'package:login_page/screens/home_Screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class VerifyAccount extends StatefulWidget {
  const VerifyAccount({super.key});

  @override
  State<VerifyAccount> createState() => _VerifyAccountState();
}

class _VerifyAccountState extends State<VerifyAccount> {
  Timer? _verificationTimer;

  @override
  void initState() {
    super.initState();
    // Start periodic verification check
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      checkVerification();
    });
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  // Mevcut kullanıcıya doğrulama emaili gönderir
  Future<void> verifyAccount() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      Get.snackbar(
        "Email Gönderildi",
        "Lütfen e-posta kutunuzu kontrol edin.",
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        "Hata",
        "Kullanıcı bulunamadı veya email zaten doğrulanmış.",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Kullanıcının e-posta doğrulama durumunu kontrol eder
  Future<void> checkVerification() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload(); // Kullanıcı verilerini güncelleyin
      if (user.emailVerified) {
        final docSnapshot =
            await FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .get();
        if (!docSnapshot.exists) {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .set({
                "displayName": user.displayName,
                "email": user.email,
                "verifiedAt": DateTime.now(),
              });
        }
        // Doğrulama başarılı, anasayfaya yönlendir
        Get.offAll(() => ProfilesScreen());
      } else {
        Get.snackbar(
          "Hesap Doğrulanmadı",
          "Lütfen e-posta kutunuzu kontrol edin ve doğrulama linkine tıklayın.",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.primaryColor.withOpacity(0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button and title
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.primaryColor),
                      onPressed: () => Get.offAll(() => const Opening()),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Hesap Doğrulama",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Welcome text
                Text(
                  "E-posta Doğrulama",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Hesabınızı doğrulamak için e-posta adresinize gönderilen linke tıklayın.",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 40),
                // Email icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.email_outlined,
                      size: 80,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Continue button
                CustomButton(
                  label: "Devam Et",
                  onPressed: checkVerification,
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  verticalPadding: 16,
                  horizontalPadding: 32,
                  borderRadius: BorderRadius.circular(12),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  isFullWidth: true,
                  elevation: 2,
                ),
                const SizedBox(height: 16),
                // Resend button
                CustomButton(
                  label: "Tekrar Gönder",
                  onPressed: verifyAccount,
                  backgroundColor: Colors.white,
                  foregroundColor: theme.primaryColor,
                  verticalPadding: 16,
                  horizontalPadding: 32,
                  borderRadius: BorderRadius.circular(12),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  isFullWidth: true,
                  isOutlined: true,
                  borderColor: theme.primaryColor,
                  elevation: 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
