import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:login_page/screens/auth/verify_account.dart';
import 'package:login_page/screens/main_navigation_screen.dart';
import 'package:login_page/services/auth_service.dart';
import 'package:login_page/widgets/custom_page_route.dart';

import 'package:login_page/widgets/socail_buttons.dart';

import 'package:login_page/widgets/text_inputs.dart';

import 'package:login_page/widgets/custom_button.dart';
import 'package:login_page/screens/auth/sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController fullName = TextEditingController();
  final TextEditingController lastName = TextEditingController();

  final AuthService _authService = AuthService();

  Future<void> signUpUser() async {
    try {
      // Kullanıcı oluşturma
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );

      User? user = userCredential.user;

      if (user != null) {
        // Kullanıcı adını güncelle
        await user.updateDisplayName("${fullName.text} ${lastName.text}");
        await user.reload();

        // Doğrulama e-postasını gönder
        await user.sendEmailVerification();

        // Doğrulama ekranına yönlendir
        // ignore: use_build_context_synchronously
        Navigator.pushReplacement(
          context,
          CustomPageRoute(child: const VerifyAccount()),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hesap oluşturulamadı: $e")));
    }
  }

  // URL'yi açmak için yardımcı bir fonksiyon
  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$urlString açılamadı')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(backgroundColor: theme.primaryColor.withOpacity(0.1)),
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // ignore: deprecated_member_use
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
                const SizedBox(height: 30),
                // Welcome text
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    textAlign: TextAlign.center,
                    "Ücretsiz kaydol!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                SocialAuthButtons(
                  facebookText: 'Kayıt Ol',
                  googleText: 'Kayıt Ol',
                  onGooglePressed: () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return const Center(child: CircularProgressIndicator());
                      },
                    );

                    // 2. Giriş işlemini yap
                    final userCredential = await _authService.signInWithGoogle(
                      context,
                    );

                    // 3. Dialog'u kapat
                    if (mounted) {
                      Navigator.of(context).pop();
                    }

                    // 4. Giriş başarılıysa yönlendir
                    if (userCredential != null && mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                  onFacebookPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Facebook ile giriş yakında eklenecek'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Divider with "veya" text
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "VEYA",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 20),

                // TextInputs widget'ları
                const SizedBox(height: 10),
                Row(
                  children: [
                    TextInputs(
                      labelText: 'İsim',
                      controller: fullName,
                      isFlexible: true,
                    ),
                    const SizedBox(width: 12),
                    TextInputs(
                      labelText: 'Soyisim',
                      controller: lastName,
                      isFlexible: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextInputs(
                  labelText: 'E-mail',
                  controller: email,
                  isEmail: true,
                ),
                const SizedBox(height: 10),
                TextInputs(
                  labelText: 'Şifre',
                  controller: password,
                  isPassword: true,
                ),
                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    children: <TextSpan>[
                      const TextSpan(text: 'Devam ederek '),
                      TextSpan(
                        text: 'Kullanım Şartları\'nı',
                        style: const TextStyle(
                          color: Colors.blue, // Tıklanabilir metin rengi
                          decoration: TextDecoration.underline, // Altı çizili
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                _launchUrl(
                                  'https://www.doktorumonline.net/kullanici-sozlesmesi',
                                );
                              },
                      ),
                      const TextSpan(text: ' kabul etmiş olursunuz.\n'),
                      TextSpan(
                        text: 'Gizlilik Politikamızı',
                        style: const TextStyle(
                          color: Colors.blue, // Tıklanabilir metin rengi
                          decoration: TextDecoration.underline, // Altı çizili
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                _launchUrl(
                                  'https://www.doktorumonline.net/gizlilik-politikasi',
                                );
                              },
                      ),
                      const TextSpan(text: ' okuyun.'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // "Kayıt Ol" butonu
                CustomButton(
                  label: "Kayıt Ol",
                  onPressed: signUpUser,
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
                // "Giriş Yap" butonu
                CustomButton(
                  label: "Zaten Hesabım Var",
                  onPressed:
                      () => Navigator.pushReplacement(
                        context,
                        CustomPageRoute(child: SignIn()),
                      ),
                  backgroundColor: Colors.white,
                  foregroundColor: theme.primaryColor,
                  verticalPadding: 16,
                  horizontalPadding: 32,
                  borderRadius: BorderRadius.circular(12),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  isFullWidth: true,
                  isOutlined: true,
                  borderColor: theme.primaryColor,
                  elevation: 0,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
