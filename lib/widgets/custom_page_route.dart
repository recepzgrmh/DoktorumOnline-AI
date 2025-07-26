import 'package:flutter/material.dart';
import 'package:login_page/services/firebase_analytics.dart';

class CustomPageRoute extends PageRouteBuilder {
  final Widget child;

  CustomPageRoute({required this.child, String? name})
    : super(
        settings: RouteSettings(name: name),
        transitionDuration: const Duration(milliseconds: 300),

        pageBuilder: (context, animation, secondaryAnimation) {
          if (name != null) {
            AnalyticsService.instance.setCurrentScreen(screenName: name);
          }
          return child;
        },

        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Offset(1.0, 0.0) demek, ekranın %100 sağından başla demek.
          // Offset.zero ise (0.0, 0.0) yani ekranın ortası, normal pozisyonu demek.
          var begin = const Offset(1.0, 0.0);
          var end = Offset.zero;

          var curve = Curves.ease;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );
}
