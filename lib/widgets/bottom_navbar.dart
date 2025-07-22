import 'package:flutter/material.dart';

class BottomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap; // Bir callback fonksiyonu ekleyin

  const BottomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap, // onTap'i zorunlu yapın
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap, // Sağlanan onTap callback'ini kullanın
      type: BottomNavigationBarType.fixed,

      // Animasyonu kaldırmak için bu satırları ekleyin
      selectedFontSize: 14, // Seçili öğenin yazı tipi boyutu
      unselectedFontSize: 14, // Seçili olmayan öğenin yazı tipi boyutu

      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          label: 'Yeni Analiz',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Raporlarım'),
        BottomNavigationBarItem(
          icon: Icon(Icons.file_copy_outlined),
          label: 'Belgelerim',
        ),

        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profiller',
        ),
      ],
    );
  }
}
