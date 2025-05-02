// lib/widgets/custom_text_widget.dart

import 'package:flutter/material.dart';

class CustomTextWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  final TextEditingController controller;

  // hatalar için bunlar
  final String? Function(String?)? validator;
  final TextStyle? errorStyle;
  final OutlineInputBorder? errorBorder;
  final OutlineInputBorder? focusedErrorBorder;

  const CustomTextWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.validator,
    this.errorStyle,
    this.errorBorder,
    this.focusedErrorBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        keyboardType: keyboardType,
        maxLines: maxLines,
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: title,
          prefixIcon: Icon(icon, color: Colors.teal),
          labelStyle: TextStyle(color: Colors.black),

          errorStyle:
              errorStyle ??
              const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
          // Normal hata kenarlığı
          errorBorder:
              errorBorder ??
              OutlineInputBorder(
                borderSide: const BorderSide(
                  color: Color.fromARGB(141, 255, 82, 82),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
          // Fokuslanmış (textarea seçiliyken) hata kenarlığı
          focusedErrorBorder:
              focusedErrorBorder ??
              OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
        ),
      ),
    );
  }
}
