import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_page/screens/home_screen.dart';
import 'package:login_page/screens/old_chat_screen.dart';
import 'package:login_page/screens/pdf_analysis_screen.dart';
import 'package:login_page/screens/profiles_screen.dart';
import 'package:login_page/screens/saved_analyses_screen.dart';
import 'package:login_page/services/auth_service.dart';
import 'package:login_page/services/tutorial_service.dart';
import 'package:login_page/widgets/bottom_navbar.dart';
import 'package:login_page/widgets/my_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Gerekli paket import edildi
import 'package:upgrader/upgrader.dart';

/// Upgrader widget'ı için özel Türkçe mesajları içeren sınıf.
/// Bu sınıf dosyanın üst seviyesinde (herhangi bir sınıfın dışında) olmalıdır.
class TurkishUpgraderMessages extends UpgraderMessages {
  @override
  String get buttonTitleIgnore => 'Yoksay';

  @override
  String get buttonTitleLater => 'Daha Sonra';

  @override
  String get buttonTitleUpdate => 'Şimdi Güncelle';

  @override
  String get prompt => 'Uygulamanın yeni bir sürümü mevcut!';

  @override
  String get title => 'Uygulama Güncellemesi';

  @override
  String get body =>
      'Uygulamanın {{appName}} {{currentAppStoreVersion}} sürümü hazır! Siz şu an {{currentInstalledVersion}} sürümünü kullanıyorsunuz.';
}

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

  /// Uygulama başlangıcında kullanıcı durumunu ve eğitimleri ayarlar.
  Future<void> _initializeUserAndTutorials() async {
    // 1. Sadece ilk açılışta eğitimleri sıfırla
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstLaunch = prefs.getBool('hasCompletedFirstLaunch') ?? true;

    if (isFirstLaunch) {
      // Eğer bu ilk açılışsa, tüm eğitimleri sıfırla.
      await TutorialService.resetAllTutorials();
      // Bayrağı (flag) false olarak ayarla ki bu blok bir daha çalışmasın.
      await prefs.setBool('hasCompletedFirstLaunch', false);
    }

    // 2. Başlangıç sayfasını belirle
    int initialIndex = 3; // Varsayılan olarak ProfilesScreen

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Kullanıcının profil dökümanı var mı diye kontrol et.
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
            // Profili olan kullanıcı ana sayfadan başlar.
            initialIndex = 0;
          }
        }
      } catch (e) {
        debugPrint("Firestore profil kontrolü sırasında hata: $e");
        // Hata durumunda, en güvenli varsayım olarak kullanıcıyı profil ekranına yönlendir.
        initialIndex = 3;
      }
    }

    // 3. Arayüzü güncelle ve eğitimi göster
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

    _showTutorialForPage(index);

    if (Scaffold.of(context).isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  /// Belirtilen index'teki sayfanın eğitimini, eğer daha önce görülmediyse gösterir.
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
        return; // Geçersiz index.
    }

    final hasSeen = await TutorialService.hasSeenTutorial(tutorialKey);
    if (!hasSeen && showFunction != null) {
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
    return UpgradeAlert(
      upgrader: Upgrader(
        //
        //debugLogging: true, // Konsolda detaylı bilgi gösterir.
        // debugDisplayOnce: true,
        // Türkçe mesajları kullanmak için kendi sınıfımızı çağırıyoruz.
        messages: TurkishUpgraderMessages(),
        countryCode: 'TR',
        languageCode: 'tr',

        // playStoreId veya appStoreId GİRİLMEMELİDİR.
        // Paket bu kimlikleri uygulamanın kendi dosyalarından
        // otomatik olarak okur.
      ),
      child: Scaffold(
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
                icon: const Icon(Icons.help_outline, size: 30),
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
                  _showTutorialForPage(_selectedIndex);
                },
                tooltip: 'Eğitimleri Sıfırla',
              ),
            // Sadece PDF Analizi sayfasındayken geçmiş butonunu göster.
            if (_selectedIndex == 2)
              IconButton(
                key: _pdfHistoryButtonKey,
                icon: const Icon(Icons.history, size: 30),
                onPressed: _onPdfHistoryTapped,
                tooltip: 'PDF Analizi Geçmişi',
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
