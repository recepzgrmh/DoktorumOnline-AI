import 'package:cloud_firestore/cloud_firestore.dart';
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

  final TextEditingController boyController = TextEditingController();
  final TextEditingController yasController = TextEditingController();
  final TextEditingController kiloController = TextEditingController();
  final TextEditingController sikayetController = TextEditingController();
  final TextEditingController sureController = TextEditingController();
  final TextEditingController ilacController = TextEditingController();
  String? _cinsiyet;

  bool _loading = false;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  late final DocumentReference<Map<String, dynamic>> userDoc;

  @override
  void initState() {
    super.initState();
    userDoc = FirebaseFirestore.instance.collection('users').doc(_uid);
  }

  @override
  void dispose() {
    boyController.dispose();
    yasController.dispose();
    kiloController.dispose();
    sikayetController.dispose();
    sureController.dispose();
    ilacController.dispose();
    super.dispose();
  }

  Future<String> _analyzeInputs() async {
    setState(() => _loading = true);

    final inputs = {
      'Boy':
          boyController.text.trim().isEmpty ? '—' : boyController.text.trim(),
      'Yaş':
          yasController.text.trim().isEmpty ? '—' : yasController.text.trim(),
      'Kilo':
          kiloController.text.trim().isEmpty ? '—' : kiloController.text.trim(),
      'Şikayet':
          sikayetController.text.trim().isEmpty
              ? '—'
              : sikayetController.text.trim(),
      'Şikayetin Süresi':
          sureController.text.trim().isEmpty ? '—' : sureController.text.trim(),
      'Mevcut İlaçlar':
          ilacController.text.trim().isEmpty ? '—' : ilacController.text.trim(),
      'Cinsiyet': _cinsiyet ?? '—',
    };

    try {
      final result = await _service.analyzeSymptoms(inputs);
      return result;
    } catch (e) {
      return 'Hata: $e';
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
                const SizedBox(height: 8),
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
                  title: 'Şikayetin Süresi',
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _loading
                            ? null
                            : () async {
                              if (!_formKey.currentState!.validate()) return;

                              // Yeni şikayet dokümanı oluştur
                              final complaintDoc =
                                  userDoc.collection('complaints').doc();
                              final complaintId = complaintDoc.id;

                              // API'den düz metin yanıt al
                              final rawResult = await _analyzeInputs();

                              // Metni "1. …", "2. …" maddelerinde böl
                              final parts =
                                  rawResult
                                      .split(RegExp(r'\n(?=\d+\.)'))
                                      .map((p) => p.trim())
                                      .where((p) => p.isNotEmpty)
                                      .toList();

                              try {
                                // Profil bilgilerini kaydet
                                await userDoc
                                    .collection('complaints')
                                    .doc(complaintId)
                                    .set({
                                      'boy': boyController.text.trim(),
                                      'yas': yasController.text.trim(),
                                      'kilo': kiloController.text.trim(),
                                      'sure': sureController.text.trim(),
                                      'ilac': ilacController.text.trim(),
                                      'sikayet': sikayetController.text.trim(),
                                      'cinsiyet': _cinsiyet ?? '',
                                      'lastAnalyzed':
                                          FieldValue.serverTimestamp(),
                                    }, SetOptions(merge: true));

                                // Her maddeyi ayrı mesaj olarak ekle
                                final col = complaintDoc.collection('messages');
                                for (var i = 0; i < parts.length; i++) {
                                  await col.add({
                                    'text': parts[i],
                                    'senderId': '2',
                                    'order': i,
                                    'sentAt': FieldValue.serverTimestamp(),
                                  });
                                }
                              } catch (e) {
                                debugPrint('Hata oluştu: $e');
                              }

                              // OverviewScreen'e yönlendir
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => OverviewScreen(
                                          uid: _uid,
                                          complaintId: complaintId,
                                        ),
                                  ),
                                );
                              }
                            },
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
