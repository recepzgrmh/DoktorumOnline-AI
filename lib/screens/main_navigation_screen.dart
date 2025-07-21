import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_page/screens/home_screen.dart';
import 'package:login_page/screens/old_chat_screen.dart';
import 'package:login_page/screens/pdf_analysis_screen.dart';
import 'package:login_page/screens/profiles_screen.dart';

import 'package:login_page/screens/saved_analyses_screen.dart';
import 'package:login_page/services/tutorial_service.dart';
import 'package:login_page/widgets/bottom_navbar.dart';
import 'package:login_page/widgets/my_drawer.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 3;

  final GlobalKey<HomeScreenState> _homeScreenKey =
      GlobalKey<HomeScreenState>();
  final GlobalKey<OldChatScreenState> _oldChatScreenKey =
      GlobalKey<OldChatScreenState>();
  final GlobalKey<PdfAnalysisScreenState> _pdfAnalysisScreenKey =
      GlobalKey<PdfAnalysisScreenState>();
  final GlobalKey<ProfilesScreenState> _profilesScreenKey =
      GlobalKey<ProfilesScreenState>();

  final GlobalKey _helpButtonKey = GlobalKey();
  final GlobalKey _pdfHistoryButtonKey = GlobalKey();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(key: _homeScreenKey),
      OldChatScreen(
        key: _oldChatScreenKey,
        userId: FirebaseAuth.instance.currentUser?.uid ?? 'default_user_id',
      ),
      PdfAnalysisScreen(
        key: _pdfAnalysisScreenKey,
        historyButtonKey: _pdfHistoryButtonKey,
      ),
      ProfilesScreen(key: _profilesScreenKey, helpButtonKey: _helpButtonKey),
    ];
    _checkUserProfileAndTriggerTutorial();
  }

  Future<void> _checkUserProfileAndTriggerTutorial() async {
    final user = FirebaseAuth.instance.currentUser;
    int initialIndex = 3; // Yeni kullanıcı için varsayılan: Profil ekranı
    bool isNewUser = true; // Kullanıcının yeni olduğunu varsayalım

    if (user != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userDoc.exists && userDoc.data()?['activeProfileId'] != null) {
          initialIndex = 0; // Mevcut kullanıcı için varsayılan: Ana ekran
          isNewUser = false; // Kullanıcının aktif profili var, yeni değil.
        }
      } catch (e) {
        debugPrint("Profil kontrol hatası: $e");
      }
    }

    // Eğer kullanıcı uygulamaya ilk defa giriyorsa, tüm eğitimleri sıfırla.
    // Böylece her sayfaya ilk gidişinde o sayfanın eğitimi tetiklenir.
    if (isNewUser) {
      await TutorialService.resetAllTutorials();
    }

    if (mounted) {
      setState(() => _selectedIndex = initialIndex);
      // UI çizildikten sonra, başlangıç ekranının eğitimini kontrol et
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerTutorialCheckFor(initialIndex);
      });
    }
  }

  /// Kullanıcı bir sekmeye dokunduğunda veya menüden seçim yaptığında çalışır.
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.of(context).pop();
    }
    // Yeni seçilen ekran için eğitimi kontrol et
    _triggerTutorialCheckFor(index);
  }

  /// Belirtilen index'teki ekranın, görülmediyse, eğitimini tetikler.
  void _triggerTutorialCheckFor(int index) {
    // Hedef widget'ların layout'unun tamamlandığından emin olmak için küçük bir gecikme
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      switch (index) {
        case 0:
          _homeScreenKey.currentState?.checkAndShowTutorialIfNeeded();
          break;
        case 1:
          _oldChatScreenKey.currentState?.checkAndShowTutorialIfNeeded();
          break;
        case 2:
          _pdfAnalysisScreenKey.currentState?.checkAndShowTutorialIfNeeded();
          break;
        case 3:
          _profilesScreenKey.currentState?.checkAndShowTutorialIfNeeded();
          break;
      }
    });
  }

  /// Sadece o anki ekranın eğitimini, görülüp görülmediğine bakmaksızın gösterir.
  /// (Yardım butonu için kullanılır).
  void _triggerCurrentScreenTutorial() {
    switch (_selectedIndex) {
      case 0:
        _homeScreenKey.currentState?.showTutorial();
        break;
      case 1:
        _oldChatScreenKey.currentState?.showTutorial();
        break;
      case 2:
        _pdfAnalysisScreenKey.currentState?.showTutorial();
        break;
      case 3:
        _profilesScreenKey.currentState?.showTutorial();
        break;
    }
  }

  void _onPdfHistoryTapped() {
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
              ? 'DoktorumOnline'
              : _selectedIndex == 1
              ? 'Geçmiş Sohbetler'
              : _selectedIndex == 2
              ? 'PDF Analizi'
              : 'Profilim',
          style: const TextStyle(color: Colors.blue),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        actions: [
          if (_selectedIndex == 3)
            IconButton(
              key: _helpButtonKey,
              icon: const Icon(Icons.help_outline),
              onPressed: () async {
                await TutorialService.resetAllTutorials();

                _triggerCurrentScreenTutorial();
              },
              tooltip: 'Eğitimleri Tekrar Göster',
            ),
          if (_selectedIndex == 2)
            IconButton(
              key: _pdfHistoryButtonKey,
              icon: const Icon(Icons.history),
              onPressed: _onPdfHistoryTapped,
              tooltip: 'PDF Analizi Geçmişi',
            ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      drawer: MyDrawer(
        onMenuItemTap: _onItemTapped,
        selectedIndex: _selectedIndex,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavbar(currentIndex: _selectedIndex, onTap: _onItemTapped),
      ),
    );
  }
}
