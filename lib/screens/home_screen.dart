// lib/screens/home_screen.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_page/screens/opening.dart';
import 'package:login_page/screens/overview_screen.dart';
import 'package:login_page/services/openai_service.dart';
import 'package:login_page/widgets/custom_text_widget.dart';
import 'package:login_page/widgets/my_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = OpenAIService();
  final _formKey = GlobalKey<FormState>();

  final boyController = TextEditingController();
  final yasController = TextEditingController();
  final kiloController = TextEditingController();
  final sikayetController = TextEditingController();
  final sureController = TextEditingController();
  final ilacController = TextEditingController();
  final illnessController = TextEditingController();
  String? _cinsiyet;
  String? _kanGrubu;

  PlatformFile? _selectedFile;

  Future<void> _pickFile() async {
    // Tek dosya seçimi
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null) return; // Kullanıcı iptal etmiş

    setState(() {
      _selectedFile = result.files.first;
    });

    // Dosyaya erişmek isterseniz:
    final filePath = _selectedFile!.path!;
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    // ...bytes üzerinde işlem yapabilirsiniz
  }

  bool _loading = false;
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  late final userDoc = FirebaseFirestore.instance.collection('users').doc(_uid);

  @override
  void dispose() {
    boyController.dispose();
    yasController.dispose();
    kiloController.dispose();
    sikayetController.dispose();
    sureController.dispose();
    ilacController.dispose();
    illnessController.dispose();
    super.dispose();
  }

  Future<void> _startFollowUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final complaintDoc = userDoc.collection('complaints').doc();
    final complaintId = complaintDoc.id;

    final inputs = <String, String>{
      'Boy': boyController.text.trim(),
      'Yaş': yasController.text.trim(),
      'Kilo': kiloController.text.trim(),
      'Şikayet': sikayetController.text.trim(),
      'Şikayet Süresi': sureController.text.trim(),
      'Mevcut İlaçlar': ilacController.text.trim(),
      'Cinsiyet': _cinsiyet ?? '',
      'Kan Grubu': _kanGrubu ?? '',
      'Kronik Rahatsızlık': illnessController.text.trim(),
    };

    try {
      // 1) Profili kaydet
      await complaintDoc.set({
        'boy': inputs['Boy'],
        'yas': inputs['Yaş'],
        'kilo': inputs['Kilo'],
        'sikayet': inputs['Şikayet'],
        'sure': inputs['Şikayet Süresi'],
        'ilac': inputs['Mevcut İlaçlar'],
        'Kronik Rahatsızlık': inputs['Kronik Rahatsızlık'],
        'cinsiyet': _cinsiyet ?? '',
        'kan_grubu': _kanGrubu ?? '',
        'lastAnalyzed': FieldValue.serverTimestamp(),
      });

      // 2) Takip sorularını direkt al
      final parts = await _service.getFollowUpQuestions(inputs);

      // 3) İlk soruyu Firestore'a ekle
      if (parts.isNotEmpty) {
        await complaintDoc.collection('messages').add({
          'text': parts[0],
          'senderId': '2', // ChatGPT
          'order': 0,
          'sentAt': FieldValue.serverTimestamp(),
        });
      }

      // 4) OverviewScreen’e inputs + complaintId + tüm soruları gönder
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => OverviewScreen(
                  uid: _uid,
                  complaintId: complaintId,
                  inputs: inputs,
                  questions: parts,
                ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Başlatma hatası: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Başlatma hatası: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const Opening()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'DoktorumOnline AI',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      drawer: const MyDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                CustomTextWidget(
                  title: 'Boy',
                  icon: Icons.straighten,
                  keyboardType: TextInputType.number,
                  controller: boyController,
                  validator:
                      (v) =>
                          v == null || v.isEmpty
                              ? 'Lütfen Boyunuzu Giriniz'
                              : null,
                ),

                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: DropdownMenu<String>(
                    hintText: 'Cinsiyetinizi Seçiniz',
                    width: double.infinity,
                    inputDecorationTheme: const InputDecorationTheme(
                      filled: true,
                    ),
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 'erkek', label: 'erkek'),
                      DropdownMenuEntry(value: 'kadın', label: 'kadın'),
                      DropdownMenuEntry(
                        value: '-',
                        label: 'Belirtmek İstemiyorum',
                      ),
                    ],
                    onSelected: (value) => setState(() => _cinsiyet = value),
                  ),
                ),
                CustomTextWidget(
                  title: 'Yaş',
                  icon: Icons.cake,
                  keyboardType: TextInputType.number,
                  controller: yasController,
                  validator:
                      (v) =>
                          v == null || v.isEmpty
                              ? 'Lütfen Yaşınızı Giriniz'
                              : null,
                ),
                CustomTextWidget(
                  title: 'Kilo',
                  icon: Icons.monitor_weight,
                  keyboardType: TextInputType.number,
                  controller: kiloController,
                  validator:
                      (v) =>
                          v == null || v.isEmpty
                              ? 'Lütfen Kilonuzu Giriniz'
                              : null,
                ),
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: DropdownMenu<String>(
                    hintText: 'Kan Grubunuzu Seçiniz',
                    width: double.infinity,
                    inputDecorationTheme: const InputDecorationTheme(
                      filled: true,
                    ),
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 'A+', label: 'A+'),
                      DropdownMenuEntry(value: 'A-', label: 'A-'),
                      DropdownMenuEntry(value: 'B+', label: 'B+'),
                      DropdownMenuEntry(value: 'B-', label: 'B-'),
                      DropdownMenuEntry(value: 'AB+', label: 'AB+'),
                      DropdownMenuEntry(value: 'AB-', label: 'AB-'),
                      DropdownMenuEntry(value: 'O+', label: 'O+'),
                      DropdownMenuEntry(value: 'O-', label: 'O-'),
                      DropdownMenuEntry(
                        value: '-',
                        label: 'Belirtmek İstemiyorum',
                      ),
                    ],
                    onSelected: (value) => setState(() => _kanGrubu = value),
                  ),
                ),
                CustomTextWidget(
                  title: 'Şikayet',
                  icon: Icons.report,
                  keyboardType: TextInputType.text,
                  controller: sikayetController,
                  maxLines: 3,
                  validator:
                      (v) =>
                          v == null || v.isEmpty
                              ? 'Lütfen Şikayetinizi Giriniz'
                              : null,
                ),
                CustomTextWidget(
                  title: 'Şikayet Süresi',
                  icon: Icons.timer,
                  keyboardType: TextInputType.text,
                  controller: sureController,
                ),
                CustomTextWidget(
                  title: 'Mevcut İlaçlar',
                  icon: Icons.local_pharmacy,
                  keyboardType: TextInputType.text,
                  controller: ilacController,
                  maxLines: 3,
                ),

                CustomTextWidget(
                  title: 'Kronik Bir Rahatsızlığınız Var Mı?',
                  icon: Icons.back_hand,
                  keyboardType: TextInputType.text,
                  controller: illnessController,
                ),

                const SizedBox(height: 10),
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(10),

                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.teal.shade50,
                    ),
                    child: Row(
                      children: [
                        Text('Seçilen dosya: '),
                        Expanded(
                          child: Text(
                            _selectedFile != null
                                ? '${_selectedFile!.name} — ${_selectedFile!.size} bytes'
                                : 'Henüz dosya seçilmedi',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.attach_file),
                          onPressed: _pickFile,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _startFollowUp,
                    child:
                        _loading
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text('Analiz Et'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
