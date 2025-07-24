import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_page/models/medical_form_data.dart';
import 'package:login_page/screens/overview_screen.dart';
import 'package:login_page/services/form_service.dart';
import 'package:login_page/services/openai_service.dart';
import 'package:login_page/services/profile_service.dart';
import 'package:login_page/services/tutorial_service.dart';
import 'package:login_page/widgets/complaint_form.dart';
import 'package:login_page/widgets/custom_button.dart';
import 'package:login_page/widgets/loading_widget.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
// *** DÜZELTİLDİ: Merkezi widget import edildi ***
import 'package:login_page/widgets/coachmark_desc.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});
  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _service = OpenAIService();
  final _formService = FormService();
  final _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();

  final sikayetController = TextEditingController();
  final sureController = TextEditingController();
  final ilacController = TextEditingController();

  MedicalFormData? _formData;
  Map<String, String> _userProfileData = {};

  bool _loading = false;
  bool _isLoadingProfile = true;
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  TutorialCoachMark? tutorialCoachMark;
  List<TargetFocus> targets = [];
  final GlobalKey _menuDrawer = GlobalKey();
  final GlobalKey _formKeyMark = GlobalKey();
  final GlobalKey _startButton = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    // Bu ekran kendi başına açıldığı için tetikleyici burada kalmalı.
  }

  @override
  void dispose() {
    sikayetController.dispose();
    sureController.dispose();
    ilacController.dispose();
    tutorialCoachMark?.finish();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profileData = await _formService.getUserProfileData();
      setState(() {
        _userProfileData = profileData;
        _isLoadingProfile = false;
      });
    } catch (e) {
      debugPrint('Profil yükleme hatası: $e');
      setState(() {
        _isLoadingProfile = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil bilgileri yüklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _startFollowUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_formData == null) return;

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
        null,
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

  // *** DÜZELTİLDİ: İsim standartlaştırıldı ve onFinish/onSkip eklendi ***
  void showTutorial() {
    _initTargets();
    if (targets.isEmpty || !mounted) return;

    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      onFinish: () => TutorialService.markTutorialAsSeen('complaint'),
      onSkip: () {
        TutorialService.markTutorialAsSeen('complaint');
        return true;
      },
    )..show(context: context, rootOverlay: true);
  }

  // *** DÜZELTİLDİ: İsim standartlaştırıldı ***
  void _initTargets() {
    targets.clear();
    targets = [
      TargetFocus(
        identify: "Drawer Key",
        keyTarget: _menuDrawer,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return CoachmarkDesc(
                text: 'Menüye buradan ulaşabilirsin',
                next: 'İleri',
                skip: 'Geç',
                onNext: controller.next,
                onSkip: controller.skip,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Form Key",
        keyTarget: _formKeyMark,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return CoachmarkDesc(
                text: 'Şikayet bilgilerinizi buraya yazın',
                next: 'İleri',
                skip: 'Geç',
                onNext: controller.next,
                onSkip: controller.skip,
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "Start Button Key",
        keyTarget: _startButton,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return CoachmarkDesc(
                text: 'Şikayetinizi başlatmak için buraya tıklayın',
                next: 'Bitir',
                skip: 'Geç',
                onNext: controller.skip,
                onSkip: controller.skip,
              );
            },
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingProfile) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Şikayet Bildirimi'),
          leading: Builder(
            builder:
                (context) => IconButton(
                  key: _menuDrawer,
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
          ),
        ),
        body: const LoadingWidget(message: "Profil bilgileri yükleniyor..."),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Şikayet Bildirimi'),
        leading: Builder(
          builder:
              (context) => IconButton(
                key: _menuDrawer,
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () async {
              await TutorialService.resetAllTutorials();
              if (mounted) {
                // Mevcut sayfanın tutorial'ını göster
                showTutorial();
              }
            },
            tooltip: 'Eğitimi Tekrar Göster',
          ),
        ],
      ),

      body:
          _loading
              ? const LoadingWidget(message: "Şikayetiniz işleniyor...")
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Container(
                          key: _formKeyMark,
                          child: ComplaintForm(
                            sikayetController: sikayetController,
                            sureController: sureController,
                            ilacController: ilacController,
                            userProfileData: _userProfileData,
                            onFormChanged: (formData) {
                              setState(() => _formData = formData);
                            },
                          ),
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
