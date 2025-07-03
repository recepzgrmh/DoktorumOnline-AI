import 'package:flutter/material.dart';
import 'package:login_page/screens/home_screen.dart';
import 'package:login_page/screens/old_chat_screen.dart';
import 'package:login_page/screens/opening.dart';
import 'package:login_page/screens/pdf_analysis_screen.dart';
import 'package:login_page/screens/profiles_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'coachmark_desc.dart' as coachmark;

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});
  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  final currentUser = FirebaseAuth.instance.currentUser;
  // ───────────────────────── Tutorial değişkenleri ──────────────────────────
  TutorialCoachMark? tutorialCoachMark;
  List<TargetFocus> targets = [];
  final GlobalKey _homeButton = GlobalKey();
  final GlobalKey _chatButton = GlobalKey();
  final GlobalKey _uploadButton = GlobalKey();
  final GlobalKey _profilesButton = GlobalKey();
  final GlobalKey _logoutButton = GlobalKey();
  // ───────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Widget build edildikten hemen sonra (ama Drawer animasyonunu bekleyerek)
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkAndShowTutorial(),
    );
  }

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();

    // Her kullanıcının kendi kaydını tutmak için e-posta ya da UID ekleyin
    final key = 'hasSeenDrawerTutorial_${currentUser?.uid ?? 'anon'}';

    final hasSeenTutorial = prefs.getBool(key) ?? false;

    if (!hasSeenTutorial && mounted) {
      _showTutorialCoachmark();

      tutorialCoachMark?.finish();
      await prefs.setBool(key, true);
    }
  }

  // Drawer kayar animasyonu tamamlandıktan sonra Coach Mark başlat
  void _showTutorialCoachmark() {
    if (!mounted) return;
    // Drawer'ın 300 ms'lik slide animasyonu için geciktir
    const drawerAnimationDelay = Duration(milliseconds: 300);
    Future.delayed(drawerAnimationDelay, () {
      if (!mounted) return;
      _initTargets();
      tutorialCoachMark = TutorialCoachMark(
        targets: targets,
        // Genel animasyon süreleri (tüm hedefler için geçerli)
        focusAnimationDuration: Duration.zero,
        unFocusAnimationDuration: Duration.zero,
        pulseAnimationDuration: const Duration(milliseconds: 350),
        pulseEnable: true,
        colorShadow: Colors.black.withOpacity(.75),
        alignSkip: Alignment.bottomRight,
        textSkip: 'Geç',
        onFinish: () => debugPrint('Drawer tutorial bitti'),
      )..show(context: context, rootOverlay: true);
    });
  }

  void _initTargets() {
    targets = [
      _buildTarget(
        identify: "Home Button",
        keyTarget: _homeButton,
        title: 'Şikayet Başlat',
        body:
            'Yeni bir muayeneye başlamak için bu butona dokun. İlgili bilgileri doldur, DoktorumOnline sana ek sorular yöneltsin.',
        focusAnim: Duration.zero,
        unFocusAnim: Duration.zero,
      ),
      _buildTarget(
        identify: "Chat Button",
        keyTarget: _chatButton,
        title: 'Analiz Geçmişi',
        body:
            'Daha önce başlattığın tüm şikâyet ve konuşmaları burada görebilirsin. '
            'Herhangi birine dokunarak detayları aç.',
        focusAnim: Duration.zero,
        unFocusAnim: Duration.zero,
      ),
      _buildTarget(
        identify: "Upload Button",
        keyTarget: _uploadButton,
        title: 'PDF Analiz',
        body:
            'Lab sonucu, kan tahlili veya reçeteni PDF olarak yükle; DoktorumOnline saniyeler içinde özetleyip kritik bulguları vurgular.',
        focusAnim: Duration.zero,
        unFocusAnim: Duration.zero,
      ),
      _buildTarget(
        identify: "Profiles Button",
        keyTarget: _profilesButton,
        title: 'Profil Yönetimi',
        body:
            'Farklı kullanıcılar için ayrı profil oluşturabilir, sağlık bilgilerini güncelleyebilirsin.',
        focusAnim: Duration.zero,
        unFocusAnim: Duration.zero,
      ),
      _buildTarget(
        identify: "Logout Button",
        keyTarget: _logoutButton,
        title: 'Güvenli Çıkış',
        body:
            'Hesabından çıkış yaparak kişisel verilerini koru. Tekrar giriş yapmak sadece birkaç saniye sürer.',
        isLast: true,
        focusAnim: Duration.zero,
        unFocusAnim: Duration.zero,
      ),
    ];
  }

  // Tek bir TargetFocus'u oluşturur
  TargetFocus _buildTarget({
    required String identify,
    required GlobalKey keyTarget,
    required String title,
    required String body,
    bool isLast = false,
    Duration focusAnim = const Duration(milliseconds: 300),
    Duration unFocusAnim = const Duration(milliseconds: 200),
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: keyTarget,
      shape: ShapeLightFocus.RRect,
      radius: 10,
      focusAnimationDuration: focusAnim,
      unFocusAnimationDuration: unFocusAnim,
      contents: [
        TargetContent(
          align: isLast ? ContentAlign.top : ContentAlign.bottom,
          builder:
              (context, controller) => coachmark.CoachmarkDesc(
                text: body,
                skip: 'Geç',
                next: isLast ? 'Bitir' : 'İleri',
                onSkip: controller.skip,
                onNext: isLast ? controller.skip : controller.next,
              ),
        ),
      ],
    );
  }

  // ─────────────────────────── Firebase sign-out ─────────────────────────────
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Opening()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Çıkış hatası: $e');
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue.shade100],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                // Kullanıcı başlığı
                UserAccountsDrawerHeader(
                  accountName: Text(
                    currentUser?.displayName ?? 'User',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  accountEmail: Text(
                    currentUser?.email ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Drawer butonları
                _buildDrawerItem(
                  key: _homeButton,
                  icon: Icons.home_rounded,
                  title: 'ŞİKAYET BAŞLAT',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                ),
                _buildDrawerItem(
                  key: _chatButton,
                  icon: Icons.chat_bubble_rounded,
                  title: 'ANALİZ GEÇMİŞİ',
                  onTap: () {
                    if (currentUser != null) {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => OldChatScreen(userId: currentUser!.uid),
                        ),
                      );
                    }
                  },
                ),
                _buildDrawerItem(
                  key: _uploadButton,
                  icon: Icons.upload_file_rounded,
                  title: 'TAHLİL YÜKLEME',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PdfAnalysisScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  key: _profilesButton,
                  icon: Icons.person,
                  title: 'PROFİLLER',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfilesScreen()),
                    );
                  },
                ),
              ],
            ),
            // Çıkış
            Container(
              key: _logoutButton,
              margin: const EdgeInsets.only(bottom: 20),
              child: _buildDrawerItem(
                icon: Icons.logout_rounded,
                title: 'LOGOUT',
                textColor: Colors.red.shade700,
                iconColor: Colors.red.shade700,
                onTap: signOut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Drawer buton şablonu
  Widget _buildDrawerItem({
    Key? key,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: ListTile(
        key: key,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(icon, color: iconColor ?? Colors.blue.shade600, size: 26),
        title: Text(
          title,
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
            color: textColor ?? Colors.blue.shade600,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        hoverColor: Colors.blue.shade50,
        selectedTileColor: Colors.blue.shade50,
      ),
    );
  }

  @override
  void dispose() {
    tutorialCoachMark?.finish();
    super.dispose();
  }
}
