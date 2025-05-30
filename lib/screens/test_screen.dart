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
    } catch (e) {
      setState(() {
        _status = 'Analiz sırasında hata: $e';
      });
    } finally {
      setState(() => _isLoading = false);
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
              onPressed: _analyzePdf,
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
            ),
            SizedBox(height: 24),
            if (_analysis != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_analysis!, style: TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
