// lib/services/analytics_service.dart

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class AnalyticsService {
  // 1. Private constructor oluştur. Bu, dışarıdan new AnalyticsService() ile örnek oluşturulmasını engeller.
  AnalyticsService._internal();

  // 2. Sınıfın tek bir örneğini (instance) oluştur.
  static final AnalyticsService instance = AnalyticsService._internal();

  // 3. FirebaseAnalytics örneğini al.
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // NavigatorObserver'ı almak için bir metod
  FirebaseAnalyticsObserver getAnalyticsObserver() =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // Metodların geri kalanı aynı kalır...
  Future<void> logLogin({required String loginMethod}) async {
    await _analytics.logLogin(loginMethod: loginMethod);
    print('✅ Analytics: logLogin gönderildi (method: $loginMethod)');
  }

  Future<void> logSignUp({required String signUpMethod}) async {
    await _analytics.logSignUp(signUpMethod: signUpMethod);
    print('✅ Analytics: logSignUp gönderildi (method: $signUpMethod)');
  }

  Future<void> setCurrentScreen({required String screenName}) async {
    await _analytics.setCurrentScreen(
      screenName: screenName,
      screenClassOverride: screenName,
    );
    print('✅ Analytics: setCurrentScreen ayarlandı (screen: $screenName)');
  }
}
