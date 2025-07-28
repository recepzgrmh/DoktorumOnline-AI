import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:login_page/screens/auth/reset_password.dart';
import 'package:login_page/screens/auth/sign_up.dart';
import 'package:login_page/screens/main_navigation_screen.dart';
import 'package:login_page/services/auth_service.dart';
import 'package:login_page/widgets/custom_page_route.dart';
import 'package:login_page/widgets/socail_buttons.dart';
import 'package:login_page/widgets/text_inputs.dart';
import 'package:login_page/wrapper.dart';
import 'package:login_page/widgets/custom_button.dart';
import 'package:url_launcher/url_launcher.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  // Giriş yapma fonksiyonu
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final AuthService _authService = AuthService();
  Future<void> signInUser() async {
    print('[DEBUG] signInUser başladı');
    try {
      print(
        '[DEBUG] FirebaseAuth.instance.signInWithEmailAndPassword çağrılıyor',
      );
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: email.text.trim(),
            password: password.text.trim(),
          );
      print('[DEBUG] signInWithEmailAndPassword başarılı');
      User? user = userCredential.user;

      if (user != null) {
        print('[DEBUG] Kullanıcı var, Wrapper ekranına yönlendiriliyor');
        // Ana ekrana yönlendir
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Wrapper()),
          );
        }
      } else {
        print('[DEBUG] Kullanıcı null');
      }
    } catch (e, s) {
      print('[ERROR] signInUser içinde hata:');
      print(e);
      print(s);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Giriş yapılamadı: $e")));
      }
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
    print('[DEBUG] SignIn build başladı');
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
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button and title
                const SizedBox(height: 40),
                // Welcome text
                SizedBox(
                  width: double.infinity,
                  child:
                      Text(
                        textAlign: TextAlign.center,
                        "welcome_back",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ).tr(),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child:
                      Text(
                        textAlign: TextAlign.center,
                        "fill_required_fields",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ).tr(),
                ),
                const SizedBox(height: 40),

                // Social media buttons
                SocialAuthButtons(
                  facebookText: 'sign_in',
                  googleText: 'sign_in',
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
                      SnackBar(content: Text('facebook_auth_coming_soon').tr()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Divider with "veya" text
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child:
                          Text(
                            "or",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ).tr(),
                    ),
                    Expanded(child: Divider(color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 20),
                // Input fields
                TextInputs(
                  labelText: 'E-mail',
                  controller: email,
                  isEmail: true,
                ),
                const SizedBox(height: 20),
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
                      TextSpan(text: 'terms_accept_text_1'.tr()),
                      TextSpan(
                        text: 'terms_of_use'.tr(),
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
                      TextSpan(text: 'terms_accept_text_2'.tr()),
                      TextSpan(
                        text: 'privacy_policy'.tr(),

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
                      TextSpan(text: 'read_privacy_policy'.tr()),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Sign in button
                CustomButton(
                  label: "sign_in".tr(),
                  onPressed: signInUser,
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
                // Forgot password button
                CustomButton(
                  label: "forgot_password",
                  onPressed:
                      () => Navigator.push(
                        context,
                        CustomPageRoute(
                          child: ResetPassword(),
                          name: 'reset_password_screen',
                        ),
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
                const SizedBox(height: 16),
                // Create account button
                CustomButton(
                  label: "sign_up_now",
                  onPressed:
                      () => Navigator.push(
                        context,
                        CustomPageRoute(
                          child: SignUp(),
                          name: 'sign_up_screen',
                        ),
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
