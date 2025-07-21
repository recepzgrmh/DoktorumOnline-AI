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
  // Başlangıçta profiller sayfasını göstermek için index 3 olarak ayarlandı.
  int _selectedIndex = 3;

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
  }

  /// DÜZELTİLDİ: Uygulama başlangıcında kullanıcı durumunu Firestore'dan kontrol eder.
  Future<void> _initializeUserAndTutorials() async {
    // Varsayılan olarak kullanıcıyı yeni ve başlangıç sayfasını profiller olarak kabul et.
    bool isNewUser = true;
    int initialIndex = 3; // ProfilesScreen

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Kullanıcının profil dökümanı var mı diye kontrol et.
        // Bu, kullanıcının en az bir profil oluşturup oluşturmadığını anlamanın en güvenilir yoludur.
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        // Eğer döküman varsa ve içinde 'profiles' listesi doluysa, kullanıcı eski kabul edilir.
        if (userDoc.exists &&
            (userDoc.data()?.containsKey('profiles') ?? false)) {
          final profiles = userDoc.data()!['profiles'] as List<dynamic>?;
          if (profiles != null && profiles.isNotEmpty) {
            isNewUser = false;
            initialIndex = 0; // Eğer eski kullanıcıysa ana sayfadan başla.
          }
        }
      } catch (e) {
        debugPrint("Firestore profil kontrolü sırasında hata: $e");
        // Hata durumunda, en güvenli varsayım olarak kullanıcıyı profil ekranına yönlendir.
        isNewUser = true;
        initialIndex = 3;
      }
    }

    // Eğer kullanıcı sistem için yeniyse, tüm eğitimleri sıfırla.
    if (isNewUser) {
      await TutorialService.resetAllTutorials();
    }

    if (mounted) {
      // Başlangıç sayfasını ayarla.
      setState(() {
        _selectedIndex = initialIndex;
      });
      // Sayfanın tamamen yüklenmesi için küçük bir gecikme sonrası eğitimi göster.
      Future.delayed(const Duration(milliseconds: 500), () {
        _showTutorialForPage(_selectedIndex);
      });
    }
  }

  /// Sayfa değiştirildiğinde çağrılır ve eğitim mantığını yönetir.
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });

    // Yeni seçilen sayfa için eğitimi göster (gerekirse).
    _showTutorialForPage(index);

    // Eğer menü açıksa kapat.
    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  /// Belirtilen index'teki sayfanın eğitimini, eğer daha önce görülmediyse gösterir.
  Future<void> _showTutorialForPage(int index) async {
    if (!mounted) return;

    String tutorialKey;
    VoidCallback? showFunction;

    // Hangi sayfanın eğitim anahtarının ve tetikleme fonksiyonunun kullanılacağını belirle.
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
        return; // Geçersiz index.
    }

    final hasSeen = await TutorialService.hasSeenTutorial(tutorialKey);
    // Eğer eğitim görülmediyse, ilgili sayfanın showTutorial fonksiyonunu çağır.
    if (!hasSeen && showFunction != null) {
      // UI'ın hazır olduğundan emin olmak için küçük bir gecikme.
      Future.delayed(const Duration(milliseconds: 200), showFunction);
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
          // Sadece Profil sayfasındayken yardım/sıfırlama butonunu göster.
          if (_selectedIndex == 3)
            IconButton(
              key: _helpButtonKey,
              icon: const Icon(Icons.help_outline),
              // Butona basıldığında tüm eğitimleri sıfırlar ve mevcut eğitimi tekrar gösterir.
              onPressed: () async {
                await TutorialService.resetAllTutorials();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tüm eğitimler sıfırlandı.'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
                // Mevcut sayfanın eğitimini yeniden tetikle.
                _showTutorialForPage(_selectedIndex);
              },
              tooltip: 'Eğitimleri Sıfırla',
            ),
          // Sadece PDF Analizi sayfasındayken geçmiş butonunu göster.
          if (_selectedIndex == 2)
            IconButton(
              key: _pdfHistoryButtonKey,
              icon: const Icon(Icons.history),
              onPressed: _onPdfHistoryTapped,
              tooltip: 'PDF Analizi Geçmişi',
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
        child: BottomNavbar(currentIndex: _selectedIndex, onTap: _onItemTapped),
      ),
    );
  }
}
