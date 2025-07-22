import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:login_page/screens/auth/reset_password.dart';
import 'package:login_page/screens/auth/sign_up.dart';
import 'package:login_page/screens/main_navigation_screen.dart';
import 'package:login_page/services/auth_service.dart';
import 'package:login_page/widgets/text_inputs.dart';
import 'package:login_page/wrapper.dart';
import 'package:login_page/widgets/custom_button.dart';

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

  @override
  Widget build(BuildContext context) {
    print('[DEBUG] SignIn build başladı');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
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
                const SizedBox(height: 40),
                // Welcome text
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    textAlign: TextAlign.center,
                    "Tekrar Hoşgeldin!",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    textAlign: TextAlign.center,
                    "Devam etmek için gerekli yerleri doldurun.",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 40),
                // Social media buttons
                Column(
                  children: [
                    Container(
                      // Google Butonu
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(134, 255, 255, 255),
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final navigator = Navigator.of(context);
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder:
                                  (_) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                            );

                            final userCredential = await _authService
                                .signInWithGoogle(context);
                            await navigator
                                .maybePop(); // Yükleme ekranını kapat

                            if (userCredential != null) {
                              navigator.pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => MainScreen()),
                                (route) => false,
                              );
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                height: 20,
                                width: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Google ile kayıt ol',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12), // Dikey boşluk
                    Container(
                      // Facebook Butonu
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(96, 255, 255, 255),
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Facebook ile giriş yakında eklenecek',
                                  textAlign: TextAlign.center,
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cd/Facebook_logo_%28square%29.png/960px-Facebook_logo_%28square%29.png',
                                height: 20,
                                width: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Facebook ile kayıt ol',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Divider with "veya" text
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white)),
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
                Text(
                  "Devam ederek Kullanım Şartları'nı kabul etmiş olursunuz.\nGizlilik Politikamızı okuyun.",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 30),
                // Sign in button
                CustomButton(
                  label: "Giriş Yap",
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
                  label: "Şifremi Unuttum",
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResetPassword(),
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
                  label: "Şimdi Hesap Oluştur",
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUp()),
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
