import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_page/widgets/text_inputs.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  TextEditingController email = TextEditingController();

  resetPassword() async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Şifremi Unuttum"),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        toolbarHeight: 100,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            children: [
              const SizedBox(height: 100),
              TextInputs(
                labelText: 'E-mail adresinizi giriniz',
                controller: email,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: resetPassword,
                child: const Text("Şifremi Sıfırla"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
