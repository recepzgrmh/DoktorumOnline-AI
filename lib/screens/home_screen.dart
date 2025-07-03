// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:login_page/models/medical_form_data.dart';
import 'package:login_page/screens/overview_screen.dart';
import 'package:login_page/services/form_service.dart';
import 'package:login_page/services/openai_service.dart';
import 'package:login_page/services/profile_service.dart';
import 'package:login_page/services/tutorial_service.dart';

import 'package:login_page/widgets/custom_appBar.dart';
import 'package:login_page/widgets/custom_button.dart';
import 'package:login_page/widgets/loading_widget.dart';
import 'package:login_page/widgets/medical_form.dart';
import 'package:login_page/widgets/complaint_form.dart';
import 'package:login_page/widgets/my_drawer.dart';

import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ═════════════ TutorialCoachMark ═════════════
  TutorialCoachMark? tutorialCoachMark;
  final List<TargetFocus> targets = [];
  final GlobalKey _startButton = GlobalKey();
  final GlobalKey _topAreaKey = GlobalKey();

  static const _scrollDuration = Duration(milliseconds: 500);
  static const _tutorialKey = 'hasSeenHomeTutorial'; // 👈 sadece cihaza özel

  // ═════════════ Services & Form ═════════════
  final _service = OpenAIService();
  final _formService = FormService();
  final _profileService = ProfileService();

  final _formKey2 = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // Full-form controllers
  final boyController = TextEditingController();
  final yasController = TextEditingController();
  final kiloController = TextEditingController();
  final sikayetController = TextEditingController();
  final sureController = TextEditingController();
  final ilacController = TextEditingController();
  final illnessController = TextEditingController();

  // Complaint-only controllers
  final complaintSikayetController = TextEditingController();
  final complaintSureController = TextEditingController();
  final complaintIlacController = TextEditingController();

  String? _cinsiyet;
  String? _kanGrubu;
  MedicalFormData? _formData;
  Map<String, String> _userProfileData = {};

  bool _loading = false;
  bool _isLoadingProfile = true;
  bool _hasProfileData = false;
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  // ───────────────────────── Lifecycle ─────────────────────────
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    // dispose controllers
    boyController.dispose();
    yasController.dispose();
    kiloController.dispose();
    sikayetController.dispose();
    sureController.dispose();
    ilacController.dispose();
    illnessController.dispose();
    complaintSikayetController.dispose();
    complaintSureController.dispose();
    complaintIlacController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ═════════════ Helpers ═════════════
  Future<void> _scrollToWidget(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: _scrollDuration,
      curve: Curves.easeInOut,
    );
  }

  bool _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: _scrollDuration,
      curve: Curves.easeInOut,
    );
    return true;
  }

  // ═════════════ Tutorial setup ═════════════
  void _initTargets() {
    targets
      ..clear()
      ..add(
        TargetFocus(
          identify: 'Start Button',
          keyTarget: _startButton,
          shape: ShapeLightFocus.RRect,
          radius: 10,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder:
                  (context, controller) => CoachmarkDesc(
                    text:
                        _hasProfileData
                            ? 'Şikayetinizi başlatmak için buraya tıklayın'
                            : 'Tüm bilgileri doldurduktan sonra şikayetinizi başlatın',
                    next: 'Bitir',
                    skip: 'Geç',
                    onNext: controller.skip,
                    onSkip: controller.skip,
                  ),
            ),
          ],
        ),
      );
  }

  /// Sayfayı önce butona kaydırır, sonra tutorial'ı gösterir.
  Future<void> _showTutorial() async {
    await _scrollToWidget(_startButton);
    _initTargets();
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      onFinish: _scrollToTop,
      onSkip: _scrollToTop,
    )..show(context: context, rootOverlay: true);
  }

  /// Drawer’daki gibi: “gördü mü?” kontrolü + gösterim
  Future<void> _checkAndShowTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(_tutorialKey) ?? false;

      if (!hasSeen && mounted) {
        await _showTutorial();
        await prefs.setBool(_tutorialKey, true);
      }
    } catch (_) {
      if (mounted) await _showTutorial(); // prefs erişilemezse bile göster
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profileData = await _formService.getUserProfileData();
      setState(() {
        _userProfileData = profileData;
        _isLoadingProfile = false;
        _hasProfileData =
            profileData['Boy']?.isNotEmpty == true &&
            profileData['Yaş']?.isNotEmpty == true &&
            profileData['Kilo']?.isNotEmpty == true &&
            profileData['Cinsiyet']?.isNotEmpty == true &&
            profileData['Kan Grubu']?.isNotEmpty == true;
      });
    } catch (e) {
      debugPrint('Profil yükleme hatası: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
        _hasProfileData = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil bilgileri yüklenemedi: $e')),
      );
    } finally {
      if (mounted) {
        // Form tam otursun diye ufak gecikme
        Future.delayed(
          const Duration(milliseconds: 400),
          _checkAndShowTutorial,
        );
      }
    }
  }

  Future<void> _startFollowUp() async {
    if (!_formKey2.currentState!.validate() || _formData == null) return;

    setState(() => _loading = true);

    try {
      final complaintDoc =
          FirebaseFirestore.instance
              .collection('users')
              .doc(_uid)
              .collection('complaints')
              .doc();
      final complaintId = complaintDoc.id;

      await _formService.saveComplaintWithProfile(
        formData: _formData!.toMap(),
        complaintId: complaintId,
      );

      final activeUserName = await _profileService.getActiveUserName();
      final parts = await _service.getFollowUpQuestions(
        _formData!.toProfileMap(),
        _formData!.toComplaintMap(),
        activeUserName,
      );

      if (parts.isNotEmpty) {
        await _formService.saveMessage(
          complaintId: complaintId,
          text: parts[0],
          senderId: '2',
        );
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => OverviewScreen(
                  uid: _uid,
                  complaintId: complaintId,
                  inputs: _formData!.toMap(),
                  questions: parts,
                ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Başlatma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Başlatma hatası: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ═════════════ UI ═════════════
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingProfile) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(title: 'DoktorumOnline AI'),
        drawer: const MyDrawer(),
        body: const LoadingWidget(
          message: 'Profil bilgileri kontrol ediliyor...',
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'DoktorumOnline AI'),
      drawer: const MyDrawer(),
      body:
          _loading
              ? const LoadingWidget(message: 'Şikayetiniz işleniyor...')
              : SafeArea(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(key: _topAreaKey, height: 1), // anchor
                        _hasProfileData
                            ? ComplaintForm(
                              sikayetController: complaintSikayetController,
                              sureController: complaintSureController,
                              ilacController: complaintIlacController,
                              userProfileData: _userProfileData,
                              onFormChanged:
                                  (d) => setState(() => _formData = d),
                            )
                            : MedicalForm(
                              boyController: boyController,
                              yasController: yasController,
                              kiloController: kiloController,
                              sikayetController: sikayetController,
                              sureController: sureController,
                              ilacController: ilacController,
                              illnessController: illnessController,
                              cinsiyet: _cinsiyet,
                              kanGrubu: _kanGrubu,
                              onCinsiyetChanged:
                                  (v) => setState(() => _cinsiyet = v),
                              onKanGrubuChanged:
                                  (v) => setState(() => _kanGrubu = v),
                              onFormChanged:
                                  (d) => setState(() => _formData = d),
                            ),
                        const SizedBox(height: 16),
                        CustomButton(
                          key: _startButton,
                          label: 'Şikayeti Başlat',
                          onPressed: _startFollowUp,
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          icon: const Icon(Icons.medical_services),
                          isFullWidth: true,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 2,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}

// ───────────────────── Coachmark açıklama widget'ı ─────────────────────
class CoachmarkDesc extends StatelessWidget {
  final String text, skip, next;
  final VoidCallback? onSkip, onNext;

  const CoachmarkDesc({
    super.key,
    required this.text,
    required this.skip,
    required this.next,
    this.onSkip,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFF2196F3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF424242),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onSkip,
                child: Text(
                  skip,
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(next, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
