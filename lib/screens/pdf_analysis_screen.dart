// lib/screens/pdf_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:login_page/widgets/custom_button.dart';
import 'package:login_page/widgets/my_drawer.dart';
import 'package:login_page/widgets/custom_appBar.dart';
import 'package:login_page/widgets/coachmark_desc.dart';

import '../services/openai_service.dart';
import '../services/pdf_analysis_service.dart';
import 'saved_analyses_screen.dart';

class PdfAnalysisScreen extends StatefulWidget {
  const PdfAnalysisScreen({super.key});

  @override
  State<PdfAnalysisScreen> createState() => _PdfAnalysisScreenState();
}

class _PdfAnalysisScreenState extends State<PdfAnalysisScreen> {
  // ═════════════ Services & State ═════════════
  final _service = OpenAIService();
  final _analysisService = PdfAnalysisService();

  PlatformFile? _selectedFile;
  String _status = 'Lütfen bir PDF dosyası seçin';
  Map<String, String>? _analysis;
  bool _isLoading = false;

  // ═════════════ TutorialCoachMark ═════════════
  TutorialCoachMark? tutorialCoachMark;
  final List<TargetFocus> targets = [];
  final GlobalKey _historyButton = GlobalKey();
  final GlobalKey _pdfPicker = GlobalKey();
  static const _tutorialKey = 'hasSeenPdfAnalysisTutorial';

  // ───────────────────────── Lifecycle ─────────────────────────
  @override
  void initState() {
    super.initState();

    // DEBUG sırasında anahtarı silmek için:
    assert(() {
      // SharedPreferences.getInstance()
      //     .then((p) => p.remove(_tutorialKey));
      return true;
    }());

    // Widget ağaçta oluştuktan sonra hafif gecikmeyle kontrol et
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), _checkAndShowTutorial);
    });
  }

  // ═════════════ Tutorial Helpers ═════════════
  Future<void> _checkAndShowTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(_tutorialKey) ?? false;

      if (!hasSeen && mounted) {
        _showTutorial();
        await prefs.setBool(_tutorialKey, true);
      }
    } catch (_) {
      if (mounted) _showTutorial(); // prefs erişilemezse bile göster
    }
  }

  void _showTutorial() {
    _initTargets();
    tutorialCoachMark = TutorialCoachMark(targets: targets)
      ..show(context: context, rootOverlay: true);
  }

  void _initTargets() {
    targets
      ..clear()
      ..addAll([
        TargetFocus(
          identify: 'History Button',
          keyTarget: _historyButton,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder:
                  (context, controller) => CoachmarkDesc(
                    text:
                        'Daha önce yaptığınız analizleri buradan görüntüleyebilir ve tekrar inceleyebilirsiniz.',
                    next: 'İleri',
                    skip: 'Geç',
                    onNext: controller.next,
                    onSkip: controller.skip,
                  ),
            ),
          ],
        ),
        TargetFocus(
          identify: 'PDF Picker',
          keyTarget: _pdfPicker,
          shape: ShapeLightFocus.RRect,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder:
                  (context, controller) => CoachmarkDesc(
                    text:
                        'PDF dosyanızı seçmek için bu butona tıklayın. Analiz etmek istediğiniz tıbbi raporu buradan yükleyebilirsiniz.',
                    next: 'Bitir',
                    skip: 'Geç',
                    onNext: controller.next,
                    onSkip: controller.skip,
                  ),
            ),
          ],
        ),
      ]);
  }

  // ═════════════ File & Analysis ═════════════
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
      _status = 'Seçilen dosya: ${_selectedFile!.name}';
      _analysis = null;
    });
  }

  Future<void> _analyzePdf() async {
    if (_selectedFile == null) {
      setState(() => _status = 'Önce bir PDF seçmelisiniz.');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Analiz yapılıyor…';
    });

    try {
      final result = await _service.analyzePdf(_selectedFile!.path!);
      setState(() {
        _analysis = result;
        _status = 'Analiz tamamlandı.';
      });

      await _analysisService.saveAnalysis(
        fileName: _selectedFile!.name,
        analysis: result,
      );

      _showAnalysisResult(result);
    } catch (e) {
      setState(() => _status = 'Analiz sırasında hata: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAnalysisResult(Map<String, String> result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              appBar: CustomAppBar(title: 'PDF Analiz Sonucu'),
              body: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.analytics,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedFile?.name ?? 'PDF Analiz Sonucu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: result.length,
                        itemBuilder: (context, index) {
                          final title = result.keys.elementAt(index);
                          final content = result[title]!;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              title: Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    content,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  // ═════════════ UI ═════════════
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const MyDrawer(),
      appBar: AppBar(
        foregroundColor: Colors.blue,
        title: const Text('PDF Analiz', style: TextStyle(color: Colors.blue)),
        actions: [
          IconButton(
            key: _historyButton,
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SavedAnalysesScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --------- Kart: PDF seçimi ----------
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.picture_as_pdf,
                        size: 64,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'PDF Dosyası Seçin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Analiz etmek istediğiniz PDF dosyasını yükleyin',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      key: _pdfPicker,
                      label: 'PDF Seç',
                      onPressed: _pickFile,
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.upload_file),
                      isFullWidth: true,
                      borderRadius: BorderRadius.circular(12),
                      elevation: 2,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            // --------- Seçilen dosya kartı ----------
            if (_selectedFile != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: theme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedFile!.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                            _status = 'Lütfen bir PDF dosyası seçin';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),
            // --------- Analiz butonu ----------
            if (_selectedFile != null)
              CustomButton(
                label:
                    _isLoading ? 'Analiz Yapılıyor...' : 'Yükle ve Analiz Et',
                onPressed: () {
                  if (_isLoading) return;
                  _analyzePdf();
                },
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.analytics),
                isFullWidth: true,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
              ),

            const SizedBox(height: 16),
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      _status.contains('hata')
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        _status.contains('hata')
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
