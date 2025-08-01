// lib/screens/pdf_analysis_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_page/services/firebase_analytics.dart';
import 'package:login_page/services/tutorial_service.dart';
import 'package:login_page/widgets/selection_bottom_sheet.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:login_page/widgets/custom_button.dart';
import 'package:login_page/widgets/custom_appbar.dart';
import 'package:login_page/widgets/coachmark_desc.dart';
import '../../services/openai_service.dart';
import '../../services/pdf_analysis_service.dart';
import 'dart:io';

class PdfAnalysisScreen extends StatefulWidget {
  final GlobalKey? historyButtonKey;
  const PdfAnalysisScreen({super.key, this.historyButtonKey});

  @override
  State<PdfAnalysisScreen> createState() => PdfAnalysisScreenState();
}

class PdfAnalysisScreenState extends State<PdfAnalysisScreen> {
  // ═════════════ Services & State ═════════════
  final _service = OpenAIService();
  final _analysisService = PdfAnalysisService();

  PlatformFile? _selectedFile;
  XFile? _selectedImage; // Resim için yeni state
  String _status = 'initial_status'.tr();
  bool _isLoading = false;
  String _selectedType = ''; // 'pdf' veya 'image'

  // ═════════════ TutorialCoachMark ═════════════
  TutorialCoachMark? tutorialCoachMark;
  final List<TargetFocus> targets = [];
  final GlobalKey _pdfPicker = GlobalKey();

  @override
  void dispose() {
    tutorialCoachMark?.finish();
    super.dispose();
  }

  void showTutorial() {
    _initTargets();
    if (targets.isEmpty || !mounted) return;
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      onFinish: () => TutorialService.markTutorialAsSeen('pdfAnalysis'),
      onSkip: () {
        TutorialService.markTutorialAsSeen('pdfAnalysis');
        return true;
      },
    )..show(context: context, rootOverlay: true);
  }

  void _initTargets() {
    targets.clear();

    if (widget.historyButtonKey?.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: 'History Button',
          keyTarget: widget.historyButtonKey,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder:
                  (context, controller) => CoachmarkDesc(
                    text: 'tutorial_history'.tr(),
                    next: 'next'.tr(),
                    skip: 'skip'.tr(),
                    onNext: controller.next,
                    onSkip: controller.skip,
                  ),
            ),
          ],
        ),
      );
    }

    if (_pdfPicker.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: 'PDF Picker',
          keyTarget: _pdfPicker,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder:
                  (context, controller) => CoachmarkDesc(
                    text: 'tutorial_select_file'.tr(),
                    next: 'finish'.tr(),
                    skip: 'skip'.tr(),
                    onNext: controller.skip,
                    onSkip: controller.skip,
                  ),
            ),
          ],
        ),
      );
    }
  }

  /// Kullanıcıya PDF mi yoksa Resim mi seçeceğini soran bir alt menü gösterir.
  void _showSourceSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SelectionBottomSheet(
            onSelectPdf: _pickFile, // PDF seçme fonksiyonunu ata
            onSelectImage: _pickImage, // Resim seçme fonksiyonunu ata
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
      _selectedImage = null; // Diğer seçimi temizle
      _selectedType = 'pdf';
      _status = tr('selected_pdf', args: [_selectedFile!.name]);
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
          _selectedFile = null; // Diğer seçimi temizle
          _selectedType = 'image';
          _status = tr('selected_image', args: [pickedFile.name]);
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
  }

  // ═════════════ Analysis Functions ═════════════
  Future<void> _analyzeContent() async {
    if (_selectedFile == null && _selectedImage == null) {
      setState(() => _status = 'must_select'.tr());
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'analyzing'.tr();
    });

    try {
      Map<String, String> result;
      String fileName;

      if (_selectedType == 'pdf' && _selectedFile != null) {
        result = await _service.analyzePdf(_selectedFile!.path!);
        fileName = _selectedFile!.name;
      } else if (_selectedType == 'image' && _selectedImage != null) {
        // Resim analizi için yeni metod
        result = await _service.analyzeImage(_selectedImage!.path);
        fileName = _selectedImage!.name;
      } else {
        throw Exception('Geçersiz dosya türü');
      }

      setState(() {
        _status = 'analysis_complete'.tr();
      });

      await _analysisService.saveAnalysis(fileName: fileName, analysis: result);

      if (mounted) {
        _showAnalysisResult(result, fileName);
      }
    } catch (e) {
      setState(() => _status = tr('analysis_error', args: [e.toString()]));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAnalysisResult(Map<String, String> result, String fileName) {
    AnalyticsService.instance.setCurrentScreen(
      screenName: 'show_analyse_screen',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              appBar: CustomAppbar(
                title:
                    _selectedType == 'pdf'
                        ? 'pdf_result'.tr()
                        : 'image_result'.tr(),
              ),
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
                            _selectedType == 'pdf'
                                ? Icons.picture_as_pdf
                                : Icons.image,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              fileName,
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
                    if (_selectedType == 'image' && _selectedImage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
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

  void _clearSelection() {
    setState(() {
      _selectedFile = null;
      _selectedImage = null;
      _selectedType = '';
      _status = 'initial_status'.tr();
    });
  }

  // ═════════════ UI ═════════════
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = _selectedFile != null || _selectedImage != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
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
                        Icons.document_scanner_outlined,
                        size: 64,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'pdf_title'.tr(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'subtitle'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      key: _pdfPicker,
                      label: 'select_file'.tr(),
                      onPressed: () {
                        AnalyticsService.instance.logButtonClick(
                          buttonName: 'file_upload_button',
                          screenName: 'pdf_analysis_screen',
                        );
                        _showSourceSelectionDialog();
                      },
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
            if (hasSelection)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _selectedType == 'pdf'
                            ? Icons.picture_as_pdf
                            : Icons.image,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedType == 'pdf'
                                  ? _selectedFile!.name
                                  : _selectedImage!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _selectedType == 'pdf'
                                  ? 'pdf_file'.tr()
                                  : 'image_file'.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _clearSelection,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (hasSelection)
              CustomButton(
                label:
                    _isLoading
                        ? 'analyzing_button'.tr()
                        : 'upload_and_analyze'.tr(),
                onPressed: () {
                  if (_isLoading) return;
                  AnalyticsService.instance.logButtonClick(
                    buttonName: 'start_analyse_button',
                    screenName: 'pdf_analysis_screen',
                  );
                  _analyzeContent();
                },
                backgroundColor: _isLoading ? Colors.grey : theme.primaryColor,
                foregroundColor: Colors.white,
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.analytics),
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
                          : _status.contains('yapılıyor')
                          ? Colors.blue.shade50
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
                            : _status.contains('yapılıyor')
                            ? Colors.blue.shade700
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
