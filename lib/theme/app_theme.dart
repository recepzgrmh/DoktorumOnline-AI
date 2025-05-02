// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Uygulamanın temel (light) teması
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.teal,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.teal.shade50,

      // textInput'un normal hali
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),

      // burada da üzerine tıklayınca değişen hali
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    // analiz et butonunun teması
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    ),

    // drawer teması
    drawerTheme: DrawerThemeData(backgroundColor: Colors.teal.shade100),
  );
}
