import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:login_page/screens/auth/verify_account.dart';
import 'package:login_page/screens/main_navigation_screen.dart';

import 'package:login_page/widgets/text_inputs.dart';

import 'package:login_page/widgets/custom_button.dart';
import 'package:login_page/screens/auth/sign_in.dart';

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
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const VerifyAccount()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Hesap oluşturulamadı: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.primaryColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Kayıt Ol",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Welcome text
                Text(
                  "Hesap Oluştur",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Başlamak İçin Kayıt Olun!",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 40),

                // TextInputs widget'ları
                TextInputs(labelText: 'İsim', controller: fullName),
                const SizedBox(height: 10),
                TextInputs(labelText: 'Soyisim', controller: lastName),
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
                Text(
                  "Devam ederek Kullanım Şartları'nı kabul etmiş olursunuz.\nGizlilik Politikamızı okuyun.",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
                        MaterialPageRoute(builder: (context) => const SignIn()),
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

                // Divider with "veya" text
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "veya",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 20),

                // Social media buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
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

                              final userCredential = await signInWithGoogle(
                                context,
                              );

                              await navigator
                                  .maybePop(); // Yükleme ekranını kapat

                              if (userCredential != null) {
                                navigator.pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => MainScreen(),
                                  ),
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
                                  'Google',
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
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
                                  // SnackBar'ın 2 saniye görünmesini sağlar
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
                                  'Facebook',
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
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<UserCredential?> signInWithGoogle(BuildContext context) async {
  try {
    // Basit Google Sign-In konfigürasyonu
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
    if (gUser == null) {
      return null;
    }

    // Token'ları al

    final gAuth = await gUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: gAuth.idToken,
      accessToken: gAuth.accessToken,
    );

    // Firebase'e ilet

    final userCred = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );

    return userCred;
  } on FirebaseAuthException catch (e) {
    if (!context.mounted) return null;

    switch (e.code) {
      case 'account-exists-with-different-credential':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bu e-posta zaten başka bir oturum yöntemiyle kayıtlı.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        break;
      case 'invalid-credential':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geçersiz kimlik bilgileri.'),
            backgroundColor: Colors.red,
          ),
        );
        break;
      case 'operation-not-allowed':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Sign-In bu projede etkin değil.'),
            backgroundColor: Colors.red,
          ),
        );
        break;
      case 'user-disabled':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu hesap devre dışı bırakılmış.'),
            backgroundColor: Colors.red,
          ),
        );
        break;
      case 'user-not-found':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcı bulunamadı.'),
            backgroundColor: Colors.red,
          ),
        );
        break;
      case 'weak-password':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre çok zayıf.'),
            backgroundColor: Colors.red,
          ),
        );
        break;
      case 'email-already-in-use':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu e-posta adresi zaten kullanımda.'),
            backgroundColor: Colors.red,
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kimlik doğrulama hatası: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
    }
    return null;
  } catch (e) {
    if (!context.mounted) return null;

    // PlatformException için özel hata yönetimi
    if (e.toString().contains('ApiException: 10')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Google Sign-In konfigürasyon hatası. Firebase Console\'u kontrol edin.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } else if (e.toString().contains('sign_in_failed')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Sign-In başarısız. Lütfen tekrar deneyin.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Beklenmeyen hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }
}
