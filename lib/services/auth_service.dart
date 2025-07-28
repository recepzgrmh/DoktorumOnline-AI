import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:login_page/screens/main_navigation_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Google ile giriş yapma ve kullanıcı verisini Firestore'a kaydetme.
  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
      if (gUser == null) {
        // Kullanıcı giriş yapmaktan vazgeçti.
        return null;
      }

      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: gAuth.idToken,
        accessToken: gAuth.accessToken,
      );

      final UserCredential userCred = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCred.user;

      // Giriş başarılı olduktan sonra, kullanıcı için Firestore'da bir doküman yoksa oluştur.
      if (user != null) {
        final docRef = _firestore.collection("users").doc(user.uid);
        final docSnapshot = await docRef.get();

        if (!docSnapshot.exists) {
          await docRef.set({
            "displayName": user.displayName,
            "email": user.email,
            "photoURL": user.photoURL,
            "createdAt":
                FieldValue.serverTimestamp(), // Sunucu zamanını kullanmak daha güvenilirdir.
            "provider":
                "google", // Kullanıcının hangi yöntemle kayıt olduğunu belirtmek faydalı olabilir.
          });
        }
      }

      return userCred;
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return null;

      // Hata mesajlarını göstermek için mevcut yapı korunmuştur.
      String message = 'Kimlik doğrulama hatası: ${e.message}';
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message = 'Bu e-posta zaten başka bir oturum yöntemiyle kayıtlı.';
          break;
        case 'invalid-credential':
          message = 'Geçersiz kimlik bilgileri.';
          break;
        case 'operation-not-allowed':
          message = 'Google Sign-In bu projede etkin değil.';
          break;
        case 'user-disabled':
          message = 'Bu hesap devre dışı bırakılmış.';
          break;
        case 'user-not-found':
          message = 'Kullanıcı bulunamadı.';
          break;
        case 'email-already-in-use':
          message = 'Bu e-posta adresi zaten kullanımda.';
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      return null;
    } catch (e) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Beklenmeyen bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  Widget getProfileAvatar({double radius = 15.0}) {
    final user = _firebaseAuth.currentUser;
    final photoURL = user?.photoURL;

    return CircleAvatar(
      radius: radius,

      backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
      backgroundColor: Colors.grey.shade300,

      child:
          photoURL == null
              ? Icon(Icons.account_circle, size: radius * 2)
              : null,
    );
  }

  /// Kullanıcının e-posta doğrulama durumunu kontrol eder.
  /// HATA DÜZELTMESİ: Bu fonksiyon navigasyon için 'BuildContext'e ihtiyaç duyuyordu.
  /// HATA DÜZELTMESİ: user.reload() sonrası güncel kullanıcı bilgisi tekrar alınmalıydı.
  Future<void> checkVerification(BuildContext context) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        // reload() sonrası en güncel kullanıcı bilgisini almak için tekrar çağırıyoruz.
        user = _auth.currentUser;

        // Kullanıcı null değilse ve email'i doğrulanmışsa devam et.
        if (user != null && user.emailVerified) {
          if (!context.mounted) return;

          // Firestore'da kullanıcı dokümanı olup olmadığını kontrol et.
          final docSnapshot =
              await _firestore.collection("users").doc(user.uid).get();

          if (!docSnapshot.exists) {
            await _firestore.collection("users").doc(user.uid).set({
              "displayName": user.displayName,
              "email": user.email,
              "verifiedAt": FieldValue.serverTimestamp(),
              "provider": "email",
            });
          }

          // Doğrulama başarılı, anasayfaya yönlendir ve geçmişi temizle.
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      debugPrint("checkVerification sırasında hata: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Doğrulama kontrolü sırasında bir hata oluştu.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Mevcut kullanıcıya doğrulama emaili gönderir
  Future<void> verifyAccount() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();

      SnackBar(
        content: Text(
          "Email Gönderildi\nLütfen e-posta kutunuzu kontrol edin.",
        ),
      );
    } else {
      SnackBar(
        content: Text(
          "Hata\nKullanıcı bulunamadı veya email zaten doğrulanmış.",
        ),
      );
    }
  }
}
