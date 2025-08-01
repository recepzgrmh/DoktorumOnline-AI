import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:login_page/screens/auth/sign_in.dart';
import 'package:login_page/screens/auth/sign_up.dart';
import 'package:login_page/services/firebase_analytics.dart';
import 'package:login_page/widgets/custom_button.dart';
import 'package:login_page/widgets/custom_page_route.dart';
import 'package:flutter_svg/flutter_svg.dart'; // 1. Import the package

class Opening extends StatefulWidget {
  const Opening({super.key});

  @override
  State<Opening> createState() => _OpeningState();
}

class _OpeningState extends State<Opening> {
  final _analytics = AnalyticsService.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: context.locale.languageCode,

              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(shape: BoxShape.rectangle),

                        child: SvgPicture.asset(
                          'assets/icon/en.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('english_language'.tr()),
                    ],
                  ),
                ),

                DropdownMenuItem(
                  value: 'tr',
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(shape: BoxShape.rectangle),
                        child: SvgPicture.asset(
                          'assets/icon/tr.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('turkish_language'.tr()),
                    ],
                  ),
                ),
              ],

              // 2. AppBar'da sadece seçili olan bayrağı göstermek için
              selectedItemBuilder: (BuildContext context) {
                return ['en', 'tr'].map((String value) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.rectangle),
                      child: SvgPicture.asset(
                        'assets/icon/$value.svg',
                        width: 28,
                        height: 28,
                      ),
                    ),
                  );
                }).toList();
              },

              // Dil değiştiğinde çalışacak fonksiyon
              onChanged: (String? newValue) {
                if (newValue != null) {
                  context.setLocale(Locale(newValue));
                }
              },
            ),
          ),
        ],
      ),
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
                  "title",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ).tr(),
                const SizedBox(height: 16),
                Text(
                  'opening',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ).tr(),
                const SizedBox(height: 48),
                // Buttons
                CustomButton(
                  label: "sign_in",
                  onPressed: () {
                    _analytics.logButtonClick(
                      buttonName: 'SignIn',
                      screenName: 'opening_screen',
                    );

                    Navigator.of(context).push(
                      CustomPageRoute(child: SignIn(), name: 'sign_in_screen'),
                    );
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
                  label: "sign_up",
                  onPressed: () {
                    _analytics.logButtonClick(
                      buttonName: 'sign_up_button',
                      screenName: 'opening_screen',
                    );

                    Navigator.of(context).push(
                      CustomPageRoute(child: SignUp(), name: 'sign_up_screen'),
                    );
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
