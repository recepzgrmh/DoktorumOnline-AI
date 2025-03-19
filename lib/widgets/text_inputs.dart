import 'package:flutter/material.dart';

class TextInputs extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final bool isPassword;
  final bool isEmail; // E-posta olup olmadığını belirlemek için yeni parametre

  const TextInputs({
    super.key,
    required this.labelText,
    required this.controller,
    this.isPassword = false,
    this.isEmail = false, // Varsayılan olarak false
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword, // Şifre için gizleme
      keyboardType:
          isEmail
              ? TextInputType.emailAddress
              : TextInputType.text, // E-posta için uygun klavye
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),

        labelText: labelText,
        suffixIcon:
            isPassword
                ? const Icon(Icons.lock) // Şifre alanı ise kilit simgesi
                : isEmail
                ? const Icon(Icons.email) // E-posta alanı ise e-posta simgesi
                : null,
      ),
    );
  }
}
