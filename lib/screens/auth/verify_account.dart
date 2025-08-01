import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:login_page/screens/opening.dart';
import 'package:login_page/services/auth_service.dart';
import 'package:login_page/services/firebase_analytics.dart';

import 'package:login_page/widgets/custom_button.dart';

import 'dart:async';

import 'package:login_page/widgets/custom_page_route.dart';

class VerifyAccount extends StatefulWidget {
  const VerifyAccount({super.key});

  @override
  State<VerifyAccount> createState() => _VerifyAccountState();
}

class _VerifyAccountState extends State<VerifyAccount> {
  Timer? _verificationTimer;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Start periodic verification check
    _verificationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _authService.checkVerification(context);
    });
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            AnalyticsService.instance.logButtonClick(
              buttonName: 'back_button',
              screenName: 'verify_account_screen',
            );

            AnalyticsService.instance.setCurrentScreen(
              screenName: 'opening_screen',
            );
            Navigator.of(
              context,
            ).pushReplacement(CustomPageRoute(child: Opening()));
          },
          icon: Icon(Icons.arrow_back_outlined),
        ),
        centerTitle: false,
        title: Text(
          'verify_account_title'.tr(),
          style: TextStyle(color: theme.primaryColor),
        ),
        backgroundColor: theme.primaryColor.withOpacity(0.1),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // ignore: deprecated_member_use
            colors: [theme.primaryColor.withOpacity(0.1), Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome text
                Text(
                  "email_verification",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ).tr(),
                const SizedBox(height: 8),
                Text(
                  "verification_instruction",
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ).tr(),
                const SizedBox(height: 40),
                // Email icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.email_outlined,
                      size: 80,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Continue button
                CustomButton(
                  label: "continue_button",
                  onPressed: () {
                    _authService.checkVerification(context);
                  },
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
                const SizedBox(height: 16),
                // Resend button
                CustomButton(
                  label: "resend_button",
                  onPressed: () {
                    _authService.verifyAccount();
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: theme.primaryColor,
                  verticalPadding: 16,
                  horizontalPadding: 32,
                  borderRadius: BorderRadius.circular(12),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  isFullWidth: true,
                  isOutlined: true,
                  borderColor: theme.primaryColor,
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
