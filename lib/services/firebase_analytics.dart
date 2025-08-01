import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

class AnalyticsService {
  AnalyticsService._internal();

  static final AnalyticsService instance = AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver getAnalyticsObserver() =>
      FirebaseAnalyticsObserver(analytics: _analytics);

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

  /// 🔴 Kullanıcının çıkış yaptığını logla
  Future<void> logSignOut({required String screenName}) async {
    await _analytics.logEvent(
      name: 'sign_out',
      parameters: {'screen': screenName},
    );
    print('✅ Analytics: logSignOut gönderildi (screen: $screenName)');
  }

  Future<void> logButtonClick({
    required String buttonName,
    required String screenName,
  }) async {
    await _analytics.logEvent(
      name: 'button_click',
      parameters: {'button_name': buttonName, 'screen': screenName},
    );
    print(
      '✅ Analytics: logButtonClick gönderildi (button: $buttonName, screen: $screenName)',
    );
  }

  Future<void> logLanguageSelected(
    String languageCode,
    String languageName,
  ) async {
    await _analytics.logEvent(
      name: 'language_selected',
      parameters: {
        'language_code': languageCode,
        'language_name': languageName,
      },
    );
    print(
      '✅ Analytics: language_selected gönderildi ($languageCode - $languageName)',
    );
  }
}
