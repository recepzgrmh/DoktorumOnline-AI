import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:login_page/widgets/custom_button.dart';
import '../services/openai_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _service = OpenAIService();
  PlatformFile? _selectedFile;
  String _status = 'Lütfen bir PDF dosyası seçin';
  String? _analysis;
  bool _isLoading = false;

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

  String _result = '';

  Future<void> _pickAndAnalyzeFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isLoading = true);
      try {
        final analysis = await _service.analyzePdf(result.files.single.path!);
        setState(() {
          _result = analysis;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _result = 'Sunucu hatası: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PDF Analiz')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.attach_file),
              label: Text('PDF Seç'),
              onPressed: _pickFile,
            ),
            SizedBox(height: 12),
            Text(_status, textAlign: TextAlign.center),
            SizedBox(height: 24),
            CustomButton(
              label: 'Yükle ve Analiz Et',
              onPressed: _pickAndAnalyzeFile,
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
            ),
            SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_result.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_result, style: TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
