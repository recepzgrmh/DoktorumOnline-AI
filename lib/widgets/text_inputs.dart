import 'package:flutter/material.dart';

class TextInputs extends StatelessWidget {
  final String labelText;

  const TextInputs({super.key, required this.labelText});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: labelText,
      ),
    );
  }
}
