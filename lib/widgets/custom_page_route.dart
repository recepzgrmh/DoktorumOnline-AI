import 'package:flutter/material.dart';

/// Auth ekranları için Fade (solma) ve Scale (büyüme) efektiyle
/// gelen modern bir sayfa geçiş animasyonu.
class CustomPageRoute extends PageRouteBuilder {
  final Widget child;

  CustomPageRoute({required this.child})
    : super(
        // Bu animasyon için 400-500ms arası daha estetik duruyor.
        transitionDuration: const Duration(milliseconds: 300),
        // Arka plandaki sayfanın görünür kalması için.
        // true yaparsak, yeni sayfa hafif transparan olduğunda arkası görünür.
        // Bu animasyon tam opak olduğu için false kalabilir.
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Büyüme (Scale) animasyonu için bir Tween.
          // Ekran %90 boyutundan başlayıp %100 boyutuna gelecek.
          var scaleTween = Tween<double>(begin: 0.90, end: 1.0);

          // Solma (Fade) animasyonu için bir Tween.
          // Ekran 0.0 opaklıktan (görünmez) başlayıp 1.0 opaklığa (tam görünür) gelecek.
          var fadeTween = Tween<double>(begin: 0.0, end: 1.0);

          // Animasyonun hızlanma/yavaşlama eğrisi.
          // fastOutSlowIn, elemanların ekrana gelirken kullandığı popüler ve şık bir curve'dür.
          var curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
          );

          // İki animasyonu birleştiriyoruz.
          // ScaleTransition, child'ını büyütürken;
          // FadeTransition, child'ını görünür hale getirir.
          return ScaleTransition(
            scale: scaleTween.animate(curvedAnimation),
            child: FadeTransition(
              opacity: fadeTween.animate(curvedAnimation),
              child: child,
            ),
          );
        },
      );
}
