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
import 'package:shared_preferences/shared_preferences.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTutorial();
    });
  }

  @override
  void dispose() {
    sikayetController.dispose();
    sureController.dispose();
    ilacController.dispose();
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
                  inputs:
                      _formData!
                          .toMap(), // Bu parametre artık kullanılmıyor ama geriye uyumluluk için bırakıyoruz
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
      setState(() => _loading = false);
    }
  }

  Future<void> _checkAndShowTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenTutorial =
          prefs.getBool('hasSeenComplaintTutorial') ?? false;
      if (!hasSeenTutorial && !_isLoadingProfile) {
        _showTutorialCoachmar();
        await prefs.setBool('hasSeenComplaintTutorial', true);
      }
    } catch (e) {
      if (!_isLoadingProfile) {
        _showTutorialCoachmar();
      }
    }
  }

  void _showTutorialCoachmar() {
    _iniTarget();
    tutorialCoachMark = TutorialCoachMark(targets: targets)
      ..show(context: context, rootOverlay: true);
  }

  void _iniTarget() {
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
                next: 'İleri',
                skip: 'Geç',
                onNext: controller.next,
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
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () async {
                // Tüm tutorial'ları sıfırla
                await TutorialService.resetAllTutorials();

                // Kullanıcıya bilgi ver
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tüm tutorial\'lar sıfırlandı. Uygulamayı yeniden başlatın veya diğer sayfalara gidip gelin.',
                      ),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }

                // Mevcut sayfanın tutorial'ını göster
                _showTutorialCoachmar();
              },
              tooltip: 'Tüm Tutorial\'ları Sıfırla',
            ),
          ],
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
              // Tüm tutorial'ları sıfırla
              await TutorialService.resetAllTutorials();

              // Kullanıcıya bilgi ver
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tüm tutorial\'lar sıfırlandı. Uygulamayı yeniden başlatın veya diğer sayfalara gidip gelin.',
                    ),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 3),
                  ),
                );
              }

              // Mevcut sayfanın tutorial'ını göster
              _showTutorialCoachmar();
            },
            tooltip: 'Tüm Tutorial\'ları Sıfırla',
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

class CoachmarkDesc extends StatefulWidget {
  final String text;
  final String skip;
  final String next;
  final void Function()? onSkip;
  final void Function()? onNext;

  const CoachmarkDesc({
    super.key,
    required this.text,
    required this.skip,
    required this.next,
    this.onSkip,
    this.onNext,
  });

  @override
  State<CoachmarkDesc> createState() => _CoachmarkDescState();
}

class _CoachmarkDescState extends State<CoachmarkDesc> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                  color: const Color(0xFF2196F3).withOpacity(0.1),
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
                  widget.text,
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
                onPressed: widget.onSkip,
                child: Text(
                  widget.skip,
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: widget.onNext,
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
                child: Text(widget.next, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
