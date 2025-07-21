import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:login_page/screens/home_screen.dart';
import 'package:login_page/screens/old_chat_screen.dart';
import 'package:login_page/screens/pdf_analysis_screen.dart';
import 'package:login_page/screens/profiles_screen.dart';
import 'package:login_page/screens/saved_analyses_screen.dart';
import 'package:login_page/widgets/bottom_navbar.dart';
import 'package:login_page/widgets/my_drawer.dart';

class TutorialService {
  static Future<void> resetAllTutorials() async {
    // Tutorial sıfırlama mantığınızı buraya ekleyin
  }
}

final GlobalKey keyButton3 = GlobalKey();

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 3; // Varsayılan olarak Profil Ekranı

  final List<Widget> _pages = [
    const HomeScreen(),
    OldChatScreen(
      userId: FirebaseAuth.instance.currentUser?.uid ?? 'default_user_id',
    ),
    const PdfAnalysisScreen(),
    const ProfilesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkUserProfile(); // Widget başlatıldığında profil kontrolü yap
  }

  Future<void> _checkUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists && userDoc.data() != null) {
        // Doküman varsa ve boş değilse devam et
        final userData = userDoc.data() as Map<String, dynamic>;

        // activeProfileId alanının varlığını kontrol et
        if (userData.containsKey('activeProfileId')) {
          setState(() {
            _selectedIndex = 0; // activeProfileId varsa Ana Ekranı başlat
          });
        } else {
          setState(() {
            _selectedIndex = 3; // activeProfileId yoksa Profil Ekranında kal
          });
        }
      } else {
        setState(() {
          _selectedIndex = 3; // Doküman yoksa Profil Ekranında kal
        });
      }
    } else {
      setState(() {
        _selectedIndex = 3;
      });
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      return; // Zaten bu sayfadaysak hiçbir şey yapma
    }

    setState(() {
      _selectedIndex = index;
    });
    // Drawer açıksa kapatmak için:
    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  void _showTutorialCoachmar() {}

  void _onPdfHistoryTapped() {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('complaints')
        .doc();

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => SavedAnalysesScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'DoktorumOnline' // Ana Ekran
              : _selectedIndex == 1
              ? 'Geçmiş Sohbetler' // Geçmiş Sohbetler Ekranı
              : _selectedIndex == 2
              ? 'PDF Analizi' // PDF Analizi Ekranı
              : 'Profilim', // Profil Ekranı (index 3)
          style: const TextStyle(color: Colors.blue),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        actions:
            _selectedIndex ==
                    3 // Profil Ekranı eylemleri
                ? [
                  IconButton(
                    key: keyButton3,
                    icon: const Icon(Icons.help_outline),
                    onPressed: () async {
                      await TutorialService.resetAllTutorials();
                      _showTutorialCoachmar();
                    },
                    tooltip: 'Tüm Tutorial\'ları Sıfırla',
                  ),
                ]
                : _selectedIndex ==
                    2 // PDF Analizi Ekranı eylemleri
                ? [
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: _onPdfHistoryTapped,
                    tooltip: 'PDF Analizi Geçmişi',
                  ),
                ]
                : [], // Diğer ekranlar için eylem yok
      ),
      body: _pages[_selectedIndex],
      drawer: MyDrawer(
        onMenuItemTap: _onItemTapped,
        selectedIndex: _selectedIndex,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          // Dokunma animasyonunu (ripple effect) kaldırır
          splashColor: Colors.transparent,
          // Basılı tutma rengini (highlight) kaldırır
          highlightColor: Colors.transparent,
        ),
        child: BottomNavbar(currentIndex: _selectedIndex, onTap: _onItemTapped),
      ),
    );
  }
}
