import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:login_page/screens/home_screen.dart';
import 'package:login_page/screens/old_chat_screen.dart';
import 'package:login_page/screens/pdf_analysis_screen.dart';
import 'package:login_page/screens/profiles_screen.dart';
import 'package:login_page/screens/saved_analyses_screen.dart';
import 'package:login_page/services/auth_service.dart';
import 'package:login_page/services/firebase_analytics.dart';
import 'package:login_page/services/tutorial_service.dart';
import 'package:login_page/widgets/bottom_navbar.dart';
import 'package:login_page/widgets/my_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Gerekli paket import edildi
import 'package:upgrader/upgrader.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Firebase Analytics için Kod
  // Başlangıçta profiller sayfasını göstermek için index 3'te.
  int _selectedIndex = 3;
  final List<int> _navigationHistory = [];

  // Her sayfanın state'ine erişmek için GlobalKey'ler.
  final GlobalKey<HomeScreenState> _homeScreenKey =
      GlobalKey<HomeScreenState>();
  final GlobalKey<OldChatScreenState> _oldChatScreenKey =
      GlobalKey<OldChatScreenState>();
  final GlobalKey<PdfAnalysisScreenState> _pdfAnalysisScreenKey =
      GlobalKey<PdfAnalysisScreenState>();
  final GlobalKey<ProfilesScreenState> _profilesScreenKey =
      GlobalKey<ProfilesScreenState>();

  // AppBar'daki butonlar için GlobalKey'ler.
  // Belki profil fotosu için de konulabilir
  final GlobalKey _helpButtonKey = GlobalKey();
  final GlobalKey _pdfHistoryButtonKey = GlobalKey();

  // Sayfaları verimli bir şekilde yüklemek için (lazy-loading).
  final List<Widget?> _pages = List.filled(4, null);

  @override
  void initState() {
    super.initState();
    // Widget ağacı oluştuktan sonra kullanıcı durumunu ve eğitimleri ayarla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserAndTutorials();
    });

    AnalyticsService.instance.setCurrentScreen(screenName: 'home');
  }

  /// Uygulama başlangıcında kullanıcı durumunu ve eğitimleri ayarlar.
  Future<void> _initializeUserAndTutorials() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Kullanıcının ilk defa giriş yapıp yapmadığını kontrol et
      final prefs = await SharedPreferences.getInstance();
      final String userInitKey = 'user_${user.uid}_initialized';
      final bool userInitialized = prefs.getBool(userInitKey) ?? false;

      if (!userInitialized) {
        // İlk defa giriş yapan kullanıcı için tutorial durumlarını temizle
        await TutorialService.resetAllTutorials();
        await prefs.setBool(userInitKey, true);
      }

      // Başlangıç sayfasını belirle
      int initialIndex = await _determineInitialPage(user);

      if (mounted) {
        setState(() {
          _selectedIndex = initialIndex;

          _navigationHistory.clear();
          _navigationHistory.add(initialIndex);
        });

        // Widget tamamen yüklendikten sonra tutorial'ı göster
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showTutorialForPage(_selectedIndex);
        });
      }
    } catch (e) {
      debugPrint("Tutorial ilklendirme hatası: $e");
    }
  }

  Future<int> _determineInitialPage(User user) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists &&
          (userDoc.data()?.containsKey('profiles') ?? false)) {
        final profiles = userDoc.data()!['profiles'] as List<dynamic>?;
        if (profiles != null && profiles.isNotEmpty) {
          return 0; // Ana sayfa
        }
      }
    } catch (e) {
      debugPrint("Firestore profil kontrolü hatası: $e");
    }

    return 3;
  }

  /// Sayfa değiştirildiğinde çağrılır ve eğitim mantığını yönetir.
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
      _navigationHistory.add(index);
    });

    String screenName;
    switch (index) {
      case 0:
        screenName = 'home_screen';
        break;
      case 1:
        screenName = 'old_chat_screen';
        break;
      case 2:
        screenName = 'pdf_analysis_screen';
        break;
      case 3:
        screenName = 'profile_Screen';
        break;
      default:
        screenName = 'unknown';
    }

    // Analytics servisini çağır
    AnalyticsService.instance.setCurrentScreen(screenName: screenName);

    //Her sayfa değişiminde ekran görüntüleme olayını gönder

    if (index == 0) {
      Future.delayed(const Duration(milliseconds: 50), () {
        _homeScreenKey.currentState?.onBecameVisible();
      });
    }

    _showTutorialForPage(index);

    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showTutorialForPage(int index) async {
    if (!mounted) return;

    String tutorialKey;
    VoidCallback? showFunction;

    switch (index) {
      case 0:
        tutorialKey = 'home';
        showFunction = _homeScreenKey.currentState?.showTutorial;
        break;
      case 1:
        tutorialKey = 'oldChats';
        showFunction = _oldChatScreenKey.currentState?.showTutorial;
        break;
      case 2:
        tutorialKey = 'pdfAnalysis';
        showFunction = _pdfAnalysisScreenKey.currentState?.showTutorial;
        break;
      case 3:
        tutorialKey = 'profiles';
        showFunction = _profilesScreenKey.currentState?.showTutorial;
        break;
      default:
        return;
    }

    try {
      final hasSeen = await TutorialService.hasSeenTutorial(tutorialKey);
      if (!hasSeen && showFunction != null && mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _selectedIndex == index) {
            showFunction!();
          }
        });
      }
    } catch (e) {
      debugPrint("Tutorial gösterim hatası: $e");
    }
  }

  void _onPdfHistoryTapped() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => SavedAnalysesScreen()));
  }

  // Lazy-loading için sayfa oluşturma mantığı.
  Widget _buildPage(int index) {
    if (_pages[index] != null) return _pages[index]!;

    switch (index) {
      case 0:
        _pages[index] = HomeScreen(key: _homeScreenKey);
        break;
      case 1:
        _pages[index] = OldChatScreen(
          key: _oldChatScreenKey,
          userId: FirebaseAuth.instance.currentUser?.uid ?? 'default_user_id',
        );
        break;
      case 2:
        _pages[index] = PdfAnalysisScreen(
          key: _pdfAnalysisScreenKey,
          historyButtonKey: _pdfHistoryButtonKey,
        );
        break;
      case 3:
        _pages[index] = ProfilesScreen(
          key: _profilesScreenKey,
          helpButtonKey: _helpButtonKey,
        );
        break;
    }
    return _pages[index]!;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Sistemin otomatik geri gitmesini engelle
      onPopInvoked: (didPop) {
        if (didPop) return;

        // Geçmişte 1'den fazla sayfa varsa bir öncekine dön
        if (_navigationHistory.length > 1) {
          setState(() {
            _navigationHistory.removeLast();
            _selectedIndex = _navigationHistory.last;
          });
        } else {
          // Sadece başlangıç sayfası kaldıysa uygulamadan çık
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(
                _selectedIndex == 0
                    ? 'DoktorumOnline'
                    : _selectedIndex == 1
                    ? 'appbar_old_chat'
                    : _selectedIndex == 2
                    ? 'appbar_pdf_analysis'
                    : 'appbar_profile',
                style: const TextStyle(color: Colors.blue),
              ).tr(),
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          actions: [
            // Sadece Profil sayfasındayken yardım/sıfırlama butonunu göster.
            if (_selectedIndex == 3)
              IconButton(
                key: _helpButtonKey,
                icon: const Icon(Icons.help_outline, size: 30),
                onPressed: () async {
                  await TutorialService.resetAllTutorials();

                  _showTutorialForPage(_selectedIndex);
                },
                tooltip: 'tooltip_reset_tutorial'.tr(),
              ),
            // Sadece PDF Analizi sayfasındayken geçmiş butonunu göster.
            if (_selectedIndex == 2)
              IconButton(
                key: _pdfHistoryButtonKey,
                icon: const Icon(Icons.history, size: 30),
                onPressed: () {
                  _onPdfHistoryTapped();
                },
                tooltip: 'tooltip_pdf_history'.tr(),
              ),

            // Sadece Anasayfadayken profil simgesi çıksın
            if (_selectedIndex == 0 || _selectedIndex == 1)
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: AuthService().getProfileAvatar(),
              ),
          ],
        ),
        // IndexedStack, sayfalar arasında geçiş yaparken state'lerini korur.
        body: IndexedStack(
          index: _selectedIndex,
          children: List.generate(4, (index) => _buildPage(index)),
        ),
        drawer: MyDrawer(
          onMenuItemTap: _onItemTapped,
          selectedIndex: _selectedIndex,
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavbar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
