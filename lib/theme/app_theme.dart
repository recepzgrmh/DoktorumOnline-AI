// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:login_page/constants/app_constants.dart';

class AppTheme {
  // Ana renk paleti
  static const Color primaryColor = Color(0xFF6C63FF); // Modern mor-mavi
  static const Color secondaryColor = Color(0xFF4A90E2); // Mavi
  static const Color backgroundColor = Color(
    0xFFF5F7FA,
  ); // Açık gri-mavi arka plan

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppConstants.primaryColor,
      scaffoldBackgroundColor: AppConstants.backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.backgroundColor,
        foregroundColor: AppConstants.textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppConstants.titleStyle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          side: const BorderSide(color: AppConstants.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AppConstants.defaultBorderRadius,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
            vertical: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: const BorderSide(color: AppConstants.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: const BorderSide(color: AppConstants.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          borderSide: const BorderSide(color: AppConstants.errorColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: 16,
        ),
        labelStyle: AppConstants.bodyStyle.copyWith(
          color: Colors.grey.shade700,
        ),
        errorStyle: AppConstants.bodyStyle.copyWith(
          color: AppConstants.errorColor,
          fontSize: 12,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: AppConstants.titleStyle,
        titleMedium: AppConstants.subtitleStyle,
        bodyLarge: AppConstants.bodyStyle,
        bodyMedium: AppConstants.bodyStyle,
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shadowColor: Colors.teal.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      ),
    );
  }
}
