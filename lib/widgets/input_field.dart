import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final String label;
  final TextInputType keyboardType;
  final int maxLines;

  const InputField({
    Key? key,
    required this.label,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        // Label’in hep üstte durmasını sağlar:
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelText: label,
        // Kutunun kenarlığı, köşe yarıçapı sıfır:
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.black54),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.black54),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: Colors.blue),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
      ),
    );
  }
}
