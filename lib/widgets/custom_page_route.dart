import 'package:flutter/material.dart';

class CustomPageRoute extends PageRouteBuilder {
  final Widget child;

  CustomPageRoute({required this.child})
    : super(
        // Animasyonun ne kadar süreceğini belirtir.
        transitionDuration: const Duration(milliseconds: 300),
        // Sayfanın kendisini oluşturan fonksiyon.
        // Bu fonksiyon genellikle sadece geçiş yapılacak widget'ı (child) döndürür.
        pageBuilder: (context, animation, secondaryAnimation) => child,
        // Animasyonun nasıl olacağını belirleyen en önemli kısım.
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Animasyonun başlangıç ve bitiş pozisyonlarını belirliyoruz.
          // Offset(1.0, 0.0) demek, ekranın %100 sağından başla demek.
          // Offset.zero ise (0.0, 0.0) yani ekranın ortası, normal pozisyonu demek.
          var begin = const Offset(1.0, 0.0);
          var end = Offset.zero;

          // Animasyonun daha yumuşak ve doğal görünmesi için bir "eğri" (curve) ekliyoruz.
          // EaseIn gibi farklı seçenekleri deneyebilirsin.
          var curve = Curves.ease;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          // SlideTransition widget'ı ile pozisyon animasyonu yapıyoruz.
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      );
}
