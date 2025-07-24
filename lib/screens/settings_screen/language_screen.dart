import 'package:flutter/material.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dil ve Bölge')),
      body: const Center(child: Text('Dil ve bölge ayarları burada olacak')),
    );
  }
}
