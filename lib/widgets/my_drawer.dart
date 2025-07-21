import 'package:flutter/material.dart';
import 'package:login_page/screens/opening.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login_page/services/tutorial_service.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'coachmark_desc.dart' as coachmark;

class MyDrawer extends StatefulWidget {
  final Function(int) onMenuItemTap;
  final int selectedIndex;

  const MyDrawer({
    super.key,
    required this.onMenuItemTap,
    required this.selectedIndex,
  });

  @override
  State<MyDrawer> createState() => MyDrawerState();
}

class MyDrawerState extends State<MyDrawer> {
  final currentUser = FirebaseAuth.instance.currentUser;
  TutorialCoachMark? tutorialCoachMark;
  List<TargetFocus> targets = [];
  final GlobalKey _homeButton = GlobalKey();
  final GlobalKey _chatButton = GlobalKey();
  final GlobalKey _uploadButton = GlobalKey();
  final GlobalKey _profilesButton = GlobalKey();
  final GlobalKey _logoutButton = GlobalKey();

  // GÜNCELLENDİ: Kod tutarlılığı için initState kullanıldı.
  @override
  void initState() {
    super.initState();
    // Widget ağacı çizildikten sonra eğitimin kontrol edilip gösterilmesini sağlar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTutorial();
    });
  }

  // didChangeDependencies metodu bu senaryo için artık gerekli değil.

  Future<void> _checkAndShowTutorial() async {
    // Drawer eğitiminin daha önce görülüp görülmediğini kontrol eder.
    final hasSeenTutorial = await TutorialService.hasSeenTutorial('drawer');

    if (!hasSeenTutorial && mounted) {
      showTutorialCoachmark();
    }
  }

  void showTutorialCoachmark() {
    if (!mounted) return;
    // Drawer animasyonunun bitmesi için küçük bir gecikme.
    const drawerAnimationDelay = Duration(milliseconds: 300);
    Future.delayed(drawerAnimationDelay, () {
      if (!mounted) return;
      _initTargets();
      if (targets.isEmpty) {
        debugPrint('Drawer tutorial için hedef bulunamadı.');
        return;
      }
      tutorialCoachMark = TutorialCoachMark(
        targets: targets,
        focusAnimationDuration: Duration.zero,
        unFocusAnimationDuration: Duration.zero,
        pulseAnimationDuration: const Duration(milliseconds: 350),
        pulseEnable: true,
        colorShadow: Colors.black.withOpacity(.75),
        alignSkip: Alignment.bottomRight,
        textSkip: 'Geç',
        onFinish: () {
          TutorialService.markTutorialAsSeen('drawer');
          debugPrint('Drawer tutorial bitti');
        },
        onSkip: () {
          TutorialService.markTutorialAsSeen('drawer');
          return true;
        },
      )..show(context: context, rootOverlay: true);
    });
  }

  void _initTargets() {
    targets = [
      _buildTarget(
        identify: "Home Button",
        keyTarget: _homeButton,
        body:
            'Yeni bir muayeneye başlamak için bu butona dokun. İlgili bilgileri doldur, DoktorumOnline sana ek sorular yöneltsin.',
      ),
      _buildTarget(
        identify: "Chat Button",
        keyTarget: _chatButton,
        body:
            'Daha önce başlattığın tüm şikâyet ve konuşmaları burada görebilirsin. Herhangi birine dokunarak detayları aç.',
      ),
      _buildTarget(
        identify: "Upload Button",
        keyTarget: _uploadButton,
        body:
            'Lab sonucu, kan tahlili veya reçeteni PDF olarak yükle; DoktorumOnline saniyeler içinde özetleyip kritik bulguları vurgular.',
      ),
      _buildTarget(
        identify: "Profiles Button",
        keyTarget: _profilesButton,
        body:
            'Farklı kullanıcılar için ayrı profil oluşturabilir, sağlık bilgilerini güncelleyebilirsin.',
      ),
      _buildTarget(
        identify: "Logout Button",
        keyTarget: _logoutButton,
        body:
            'Hesabından çıkış yaparak kişisel verilerini koru. Tekrar giriş yapmak sadece birkaç saniye sürer.',
        isLast: true,
      ),
    ];
  }

  TargetFocus _buildTarget({
    required String identify,
    required GlobalKey keyTarget,
    required String body,
    bool isLast = false,
  }) {
    return TargetFocus(
      identify: identify,
      keyTarget: keyTarget,
      shape: ShapeLightFocus.RRect,
      radius: 10,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış yaparken bir hata oluştu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Bu kısımdaki UI kodlarında değişiklik yapılmadı.
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
                _buildDrawerItem(
                  key: _homeButton,
                  icon: Icons.home_rounded,
                  title: 'ŞİKAYET BAŞLAT',
                  index: 0,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onMenuItemTap(0);
                  },
                ),
                _buildDrawerItem(
                  key: _chatButton,
                  icon: Icons.chat_bubble_rounded,
                  title: 'ANALİZ GEÇMİŞİ',
                  index: 1,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onMenuItemTap(1);
                  },
                ),
                _buildDrawerItem(
                  key: _uploadButton,
                  icon: Icons.upload_file_rounded,
                  title: 'TAHLİL YÜKLEME',
                  index: 2,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onMenuItemTap(2);
                  },
                ),
                _buildDrawerItem(
                  key: _profilesButton,
                  icon: Icons.person,
                  title: 'PROFİLLER',
                  index: 3,
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onMenuItemTap(3);
                  },
                ),
              ],
            ),
            Container(
              key: _logoutButton,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
                left: 15,
                right: 15,
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade700,
                  size: 26,
                ),
                title: Text(
                  'ÇIKIŞ YAP',
                  style: TextStyle(
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop(); // Drawer'ı kapat
                  signOut(); // Firebase çıkış işlemi
                },
                hoverColor: Colors.red.shade50,
                selectedTileColor: Colors.red.shade50.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    Key? key,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required int index,
    Color? textColor,
    Color? iconColor,
  }) {
    final isSelected = widget.selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: ListTile(
        key: key,
        selected: isSelected,
        selectedTileColor: Colors.blue.shade100.withOpacity(0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          icon,
          color:
              isSelected
                  ? Colors.blue.shade700
                  : (iconColor ?? Colors.blue.shade600),
          size: 26,
        ),
        title: Text(
          title,
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color:
                isSelected
                    ? Colors.blue.shade700
                    : (textColor ?? Colors.blue.shade600),
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        hoverColor: Colors.blue.shade50,
      ),
    );
  }

  @override
  void dispose() {
    tutorialCoachMark?.finish();
    super.dispose();
  }
}
