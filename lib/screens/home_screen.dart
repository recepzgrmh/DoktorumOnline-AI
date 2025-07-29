// lib/screens/home_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_page/screens/pdf_analysis_screen.dart';
import 'package:login_page/services/tutorial_service.dart';
import 'package:login_page/models/medical_form_data.dart';
import 'package:login_page/screens/overview_screen.dart';
import 'package:login_page/services/form_service.dart';
import 'package:login_page/services/openai_service.dart';
import 'package:login_page/services/profile_service.dart';
import 'package:login_page/widgets/coachmark_desc.dart';
import 'package:login_page/widgets/custom_button.dart';
import 'package:login_page/widgets/loading_widget.dart';
import 'package:login_page/widgets/medical_form.dart';
import 'package:login_page/widgets/complaint_form.dart';
import 'package:login_page/widgets/selection_bottom_sheet.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // ═════════════ TutorialCoachMark ═════════════
  TutorialCoachMark? tutorialCoachMark;
  final List<TargetFocus> targets = [];
  final GlobalKey _startButton = GlobalKey();
  final GlobalKey _topAreaKey = GlobalKey();
  final FocusNode _complaintFocusNode = FocusNode();

  final _analysisService = PdfAnalysisScreen();

  PlatformFile? _selectedFile;
  XFile? _selectedImage; // Resim için yeni state
  String _status = 'select_file_or_image'.tr();
  bool _isLoading = false;
  String _selectedType = ''; // 'pdf' veya 'image'

  static const _scrollDuration = Duration(milliseconds: 500);

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

  StreamSubscription<DocumentSnapshot>? _profileSubscription;

  // ───────────────────────── Lifecycle ─────────────────────────
  @override
  void initState() {
    super.initState();

    _listenToProfileUpdates();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
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
    _complaintFocusNode.dispose();
    super.dispose();
  }

  void onBecameVisible() {
    if (_hasProfileData) {
      complaintSikayetController.clear();
      complaintSureController.clear();
      complaintIlacController.clear();

      setState(() {
        _formData = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _complaintFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  // ═════════════ Tutorial Setup ═════════════

  void _initTargets() {
    targets.clear();
    if (_startButton.currentContext != null) {
      targets.add(
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
                            ? 'tutorial_start_complaint'.tr()
                            : 'tutorial_start_complaint_noUser'.tr(),
                    next: 'finish'.tr(),
                    skip: 'skip'.tr(),
                    onNext: () {
                      controller.skip();
                    },
                    onSkip: () {
                      controller.skip();
                    },
                  ),
            ),
          ],
        ),
      );
    }
  }

  void showTutorial() {
    _scrollToWidget(_startButton).then((_) {
      _initTargets();
      if (targets.isEmpty || !mounted) return;

      tutorialCoachMark = TutorialCoachMark(
        targets: targets,
        onFinish: () {
          TutorialService.markTutorialAsSeen('home');
          _scrollToTop();
        },
        onSkip: () {
          TutorialService.markTutorialAsSeen('home');
          _scrollToTop();
          return true;
        },
      )..show(context: context, rootOverlay: true);
    });
  }

  // ═════════════ Data Handling ═════════════

  void _listenToProfileUpdates() {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(_uid);

    _profileSubscription = userDoc.snapshots().listen(
      (snapshot) {
        if (!mounted) return;

        Map<String, String> profileData = {};
        bool hasData = false;

        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;

          // Önce aktif profil var mı diye kontrol et
          final profiles = data['profiles'] as List<dynamic>? ?? [];
          final activeProfile = profiles.firstWhere(
            (profile) => profile['isActive'] == true,
            orElse: () => {},
          );

          if (activeProfile.isNotEmpty) {
            // Aktif profil varsa onun bilgilerini kullan
            profileData = {
              'Boy': activeProfile['height']?.toString() ?? '',
              'Yaş': activeProfile['age']?.toString() ?? '',
              'Kilo': activeProfile['weight']?.toString() ?? '',
              'Cinsiyet': activeProfile['gender']?.toString() ?? '',
              'Kan Grubu': activeProfile['bloodType']?.toString() ?? '',
              'Kronik Rahatsızlık':
                  activeProfile['chronicIllness']?.toString() ?? '',
            };
          } else {
            // Eski yapıyı kullan (geriye uyumluluk için)
            profileData = {
              'Boy': data['boy']?.toString() ?? '',
              'Yaş': data['yas']?.toString() ?? '',
              'Kilo': data['kilo']?.toString() ?? '',
              'Cinsiyet': data['cinsiyet']?.toString() ?? '',
              'Kan Grubu': data['kan_grubu']?.toString() ?? '',
              'Kronik Rahatsızlık':
                  data['kronik_rahatsizlik']?.toString() ?? '',
            };
          }

          hasData =
              profileData['Boy']?.isNotEmpty == true &&
              profileData['Yaş']?.isNotEmpty == true &&
              profileData['Kilo']?.isNotEmpty == true &&
              profileData['Cinsiyet']?.isNotEmpty == true &&
              profileData['Kan Grubu']?.isNotEmpty == true;
        }

        setState(() {
          _userProfileData = profileData;
          _hasProfileData = hasData;
          _isLoadingProfile = false;
        });
      },
      onError: (e) {
        debugPrint('Profil dinleme hatası: $e');
        if (!mounted) return;
        setState(() {
          _isLoadingProfile = false;
          _hasProfileData = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil bilgileri alınamadı: $e')),
        );
      },
    );
  }

  Future<void> _startFollowUp() async {
    // 1. Formun geçerliliğini ve formData'nın dolu olduğunu kontrol et.
    if (!_formKey2.currentState!.validate() || _formData == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('fill_all_required_fields'.tr())));
      return;
    }

    // 2. Yükleme animasyonunu başlat.
    setState(() => _loading = true);

    Map<String, String>? fileAnalysis;

    try {
      if (!_hasProfileData) {
        await _profileService.addProfile(
          name: 'main_profile'.tr(),
          age: int.parse(yasController.text),
          height: int.parse(boyController.text),
          weight: double.parse(kiloController.text),
          gender: _cinsiyet!,
          bloodType: _kanGrubu!,

          chronicIllness: illnessController.text,
        );
      }
      // 3. Dosya analizi (varsa).
      if (_selectedFile != null && _selectedFile!.path != null) {
        setState(() => _status = 'file_analysis_in_progress'.tr());
        fileAnalysis = await _service.analyzePdf(_selectedFile!.path!);
      } else if (_selectedImage != null) {
        setState(() => _status = 'image_analysis_in_progress'.tr());
        fileAnalysis = await _service.analyzeImage(_selectedImage!.path);
      }

      if (fileAnalysis != null && fileAnalysis.containsKey('Hata')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'file_analysis_error'.tr(args: [fileAnalysis['Hata'].toString()]),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );

        return;
      }

      // 4. OpenAI servisinden soruları veya hata mesajını al.
      final activeUserName = await _profileService.getActiveUserName();
      final parts = await _service.getFollowUpQuestions(
        _formData!.toProfileMap(),
        _formData!.toComplaintMap(),
        activeUserName!,
        fileAnalysis,
      );

      // 5. Servisten dönen cevabı kontrol et.
      // Eğer cevap "geçersiz şikayet" hata mesajı ise SnackBar göster ve işlemi durdur.
      if (mounted &&
          parts.length == 1 &&
          parts.first == 'invalid_complaint_error'.tr()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(parts.first),
            backgroundColor: Colors.orange.shade800, // Uyarı rengi
          ),
        );

        return;
      }

      // 6. Şikayet geçerliyse, Firestore'a kaydı yap.
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

      // 7. İlk mesajı kaydet.
      if (parts.isNotEmpty) {
        await _formService.saveMessage(
          complaintId: complaintId,
          text: parts[0],
          senderId: '2',
        );
      }

      // 8. OverviewScreen'e yönlendir.
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
                  fileAnalysis: fileAnalysis,
                ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Takip başlatma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error'.tr(args: [e.toString()]))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _clearSelection();
        });
      }
    }
  }

  /// Kullanıcıya PDF mi yoksa Resim mi seçeceğini soran bir alt menü gösterir.
  void _showSourceSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SelectionBottomSheet(
            onSelectPdf: _pickFile,
            onSelectImage: _pickImage,
          ),
    );
  }

  // ═════════════ File & Image Selection ═════════════
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null) return;

    setState(() {
      _selectedFile = result.files.first;
      _selectedImage = null;
      _selectedType = 'pdf';
      _status = 'selected_file'.tr(args: [_selectedFile!.name]);
    });
  }

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();

    try {
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = pickedFile;
          _selectedFile = null;
          _selectedType = 'image';
          _status = 'selected_image'.tr(args: [_selectedImage!.name]);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('image_selection_error'.tr(args: [e.toString()])),
        ),
      );
      print("Resim seçilirken bir hata ile karşılaşıldı: $e");
    }

    // ═════════════ UI ═════════════
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Dosya seçilip seçilmediğini kontrol eden bir değişken
    final bool isFileSelected = _selectedFile != null || _selectedImage != null;

    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: LoadingWidget(message: 'loading_profile'),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body:
          _loading
              ? LoadingWidget(message: 'processing_complaint'.tr())
              : SafeArea(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(key: _topAreaKey, height: 1),
                        const SizedBox(height: 24),
                        _hasProfileData
                            ? ComplaintForm(
                              complaintFocusNode: _complaintFocusNode,
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

                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                label:
                                    isFileSelected
                                        ? _status
                                        : 'upload_file'.tr(),
                                onPressed: _showSourceSelectionDialog,

                                backgroundColor:
                                    isFileSelected
                                        ? Colors.green.shade700
                                        : Colors.teal,
                                foregroundColor: Colors.white,
                                isFullWidth: true,
                                borderRadius: BorderRadius.circular(12),
                                elevation: 2,
                              ),
                            ),

                            if (isFileSelected)
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: _clearSelection,
                                  tooltip: 'clear_selection'.tr(),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        CustomButton(
                          key: _startButton,
                          label: 'start_complaint'.tr(),
                          onPressed: _startFollowUp,
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
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

  void _clearSelection() {
    setState(() {
      _selectedFile = null;
      _selectedImage = null;
      _selectedType = '';
      _status = 'select_file_or_image'.tr();
    });
  }
}
