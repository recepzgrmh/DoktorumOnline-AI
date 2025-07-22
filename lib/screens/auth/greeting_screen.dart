import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:login_page/screens/main_navigation_screen.dart';
import 'package:login_page/wrapper.dart';

class GreetingScreen extends StatefulWidget {
  const GreetingScreen({super.key});

  @override
  State<GreetingScreen> createState() => _GreetingScreenState();
}

class _GreetingScreenState extends State<GreetingScreen> {
  // Giriş yapma fonksiyonu

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
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
                          (_) =>
                              const Center(child: CircularProgressIndicator()),
                    );

                    final userCredential = await signInWithGoogle(context);

                    await navigator.maybePop(); // Yükleme ekranını kapat

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
        ],
      ),
    );
  }
}
