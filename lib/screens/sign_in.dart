import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_page/screens/reset_password.dart';
import 'package:login_page/screens/sign_up.dart';
import 'package:login_page/widgets/text_inputs.dart';
import 'package:get/get.dart';
import 'package:login_page/wrapper.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  // Giriş yapma fonksiyonu
  Future<void> signInUser() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      User? user = userCredential.user;

      if (user != null) {
        print("🔥 Kullanıcı giriş yaptı: ${user.email}");
        print("📌 Kullanıcı UID: ${user.uid}");

        // **Ana ekrana yönlendir**
        Get.offAll(() => const Wrapper());
      }
    } catch (e) {
      print("🚨 Firebase Giriş Hatası: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Giriş yapılamadı: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Klavye açıldığında taşma olmaması için
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),

        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık
              const SizedBox(height: 10),
              Text(
                "Tekrar Hoşgeldin!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Devam etmek için gerekli yerleri doldurun.",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),

              // E-mail ve Şifre alanları
              const SizedBox(height: 40),
              TextInputs(labelText: 'E-mail', controller: email, isEmail: true),
              const SizedBox(height: 20),
              TextInputs(
                labelText: 'Şifre',
                controller: password,
                isPassword: true,
              ),

              // Bilgilendirme metni
              const SizedBox(height: 20),
              Text(
                "Devam ederek Kullanım Şartları'nı kabul etmiş olursunuz.\nGizlilik Politikamızı okuyun.",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),

              // Butonlar
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: signInUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(48),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  "Giriş Yap",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.to(const ResetPassword()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8EEF2),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  "Şifremi Unuttum",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Get.to(const SignUp()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8EEF2),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  "Şimdi Hesap Oluştur",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
