// lib/screens/test_screen.dart

import 'package:flutter/material.dart';
import '../services/openai_service.dart';

class TestScreen extends StatefulWidget {
  final String imageUrl;

  const TestScreen({super.key, required this.imageUrl});

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String? _description;
  final _service = OpenAIService();

  @override
  void initState() {
    super.initState();
    _loadDescription();
  }

  Future<void> _loadDescription() async {
    try {
      final desc = await _service.identifyFruit(widget.imageUrl);
      setState(() {
        _description = desc;
      });
    } catch (e) {
      setState(() {
        _description = 'Meyve tanımlanırken hata oluştu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Screen')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                widget.imageUrl,
                errorBuilder:
                    (_, __, ___) =>
                        Icon(Icons.broken_image, size: 80, color: Colors.grey),
              ),
              SizedBox(height: 12),
              if (_description == null)
                CircularProgressIndicator()
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _description!,
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
