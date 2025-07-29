import 'package:easy_localization/easy_localization.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("reset_link_sent".tr())));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("error_message".tr(args: [e.toString()]))),
      );
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
                  child:
                      Text(
                        textAlign: TextAlign.center,
                        "forgot_password_title",
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
                        "forgot_password_send_mail",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ).tr(),
                ),
                const SizedBox(height: 40),
                TextInputs(
                  labelText: 'E-mail',
                  controller: email,
                  isEmail: true,
                ),
                const SizedBox(height: 30),
                CustomButton(
                  label: "send_reset_link".tr(),
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
