import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_page/widgets/text_inputs.dart';
import 'package:login_page/widgets/custom_button.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  TextEditingController email = TextEditingController();

  Future<void> resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifre sıfırlama bağlantısı gönderildi!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      resizeToAvoidBottomInset: true,
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
                const SizedBox(height: 40),
                // Welcome text
                Text(
                  "Şifreni mi Unuttun?",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Hesabınızla ilişkili e-posta adresini girin, size şifrenizi sıfırlamanız için bir bağlantı gönderelim.",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 40),
                TextInputs(
                  labelText: 'E-mail',
                  controller: email,
                  isEmail: true,
                ),
                const SizedBox(height: 30),
                CustomButton(
                  label: "Sıfırlama Linki Gönder",
                  onPressed: resetPassword,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
