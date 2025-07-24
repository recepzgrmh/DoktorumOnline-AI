// lib/screens/home_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'dart:async'; // StreamSubscription için eklendi
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
  String _status = 'Lütfen bir PDF dosyası veya resim seçin';
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
                            ? 'Şikayetinizi başlatmak için buraya tıklayın'
                            : 'Tüm bilgileri doldurduktan sonra şikayetinizi başlatın',
                    next: 'Bitir',
                    skip: 'Geç',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm zorunlu alanları doldurun.')),
      );
      return;
    }

    // 2. Yükleme animasyonunu başlat.
    setState(() => _loading = true);

    // Analiz sonuçlarını tutacak değişkeni oluştur.
    Map<String, String>? fileAnalysis;

    // Hata yönetimi için her şeyi try-catch-finally içine al.
    try {
      // 3. Seçili bir dosya varsa, türüne göre analiz et (PDF veya Resim).
      if (_selectedFile != null && _selectedFile!.path != null) {
        setState(
          () => _status = 'PDF dosyası analiz ediliyor...',
        ); // Arayüzde durum bildir
        fileAnalysis = await _service.analyzePdf(_selectedFile!.path!);
      } else if (_selectedImage != null) {
        setState(
          () => _status = 'Resim dosyası analiz ediliyor...',
        ); // Arayüzde durum bildir
        fileAnalysis = await _service.analyzeImage(_selectedImage!.path);
      }

      // Analizden bir hata dönerse, kullanıcıyı bilgilendir ve işlemi durdur.
      if (fileAnalysis != null && fileAnalysis.containsKey('Hata')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosya analizi hatası: ${fileAnalysis['Hata']}'),
          ),
        );
        return; // return, finally bloğunu tetikler ve işlemi sonlandırır.
      }

      // 4. Firestore'a şikayet kaydını yap (Bu kısım eskisiyle aynı).
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

      // 5. Dosya Analizi Soru Cevap Akışıyla birlikte
      final activeUserName = await _profileService.getActiveUserName();
      final parts = await _service.getFollowUpQuestions(
        _formData!.toProfileMap(),
        _formData!.toComplaintMap(),
        activeUserName,
        fileAnalysis,
      );

      // 6. İlk mesajı kaydet ve sonraki ekrana geç.
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
                  fileAnalysis:
                      fileAnalysis, // Analiz sonucunu bir sonraki ekrana da yolla
                ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Takip başlatma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Bir hata oluştu: $e')));
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
      _status = 'Seçilen dosya: ${_selectedFile!.name}';
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
          _status = 'Seçilen resim: ${pickedFile.name}';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resim seçilirken bir hata oluştu: $e')),
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
        body: LoadingWidget(message: 'Profil bilgileri kontrol ediliyor...'),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
                        Container(
                          key: _topAreaKey,
                          height: 1,
                        ), // Anchor for scroll
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
                                label: isFileSelected ? _status : 'Dosya yükle',
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
                                  tooltip: 'Seçimi Temizle',
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        CustomButton(
                          key: _startButton,
                          label: 'Şikayeti Başlat',
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
      _status = 'Lütfen bir PDF dosyası veya resim seçin';
    });
  }
}
