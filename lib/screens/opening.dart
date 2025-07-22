import 'package:flutter/material.dart';
import 'package:login_page/screens/auth/sign_in.dart';
import 'package:login_page/screens/auth/sign_up.dart';
import 'package:login_page/widgets/custom_button.dart';
import 'package:login_page/widgets/custom_page_route.dart';

class Opening extends StatelessWidget {
  const Opening({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo and Welcome Text
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.medical_services_outlined,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'DoktorumOnline AI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Yapay zeka destekli sağlık asistanınıza hoş geldiniz',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 48),
                // Buttons
                CustomButton(
                  label: "Giriş Yap",
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(CustomPageRoute(child: SignIn()));
                  },
                  backgroundColor: Theme.of(context).primaryColor,
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
                CustomButton(
                  label: "Kayıt Ol",
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(CustomPageRoute(child: SignUp()));
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).primaryColor,
                  verticalPadding: 16,
                  horizontalPadding: 32,
                  borderRadius: BorderRadius.circular(12),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  isFullWidth: true,
                  isOutlined: true,
                  borderColor: Theme.of(context).primaryColor,
                  elevation: 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
