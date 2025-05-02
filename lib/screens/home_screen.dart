import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:login_page/screens/opening.dart';
import 'package:login_page/screens/overview_screen.dart';
import 'package:login_page/services/openai_service.dart';
import 'package:login_page/widgets/custom_text_widget.dart';
import 'package:login_page/widgets/my_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = OpenAIService();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  final TextEditingController boyController = TextEditingController();
  final TextEditingController yasController = TextEditingController();
  final TextEditingController kiloController = TextEditingController();
  final TextEditingController sikayetController = TextEditingController();
  final TextEditingController sureController = TextEditingController();
  final TextEditingController ilacController = TextEditingController();
  String? _cinsiyet;

  bool _loading = false;

  // Kullanıcının girmiş olduğu verileri saklamak için problem adlı collection oluşturduk
  final collection = FirebaseFirestore.instance.collection("problem");

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
    setState(() {
      _loading = true;
    });

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
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (ctx) => const Opening()));
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen Boyunuzu Giriniz';
                    }
                    return null;
                  },
                ),

                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),

                  child: DropdownMenu<String>(
                    hintText: 'Cinsiyetinizi Seçiniz',
                    width: double.infinity,
                    inputDecorationTheme: InputDecorationTheme(filled: true),
                    dropdownMenuEntries: [
                      DropdownMenuEntry(value: 'erkek', label: 'erkek'),
                      DropdownMenuEntry(value: 'kadın', label: 'kadın'),
                      DropdownMenuEntry(
                        value: '-',
                        label: 'Belirtmek İstemiyorum',
                      ),
                    ],
                  ),
                ),
                CustomTextWidget(
                  title: 'Yaş',
                  icon: Icons.cake,
                  keyboardType: TextInputType.number,
                  controller: yasController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen Yaşınızı Giriniz';
                    }
                    return null;
                  },
                ),
                CustomTextWidget(
                  title: 'Kilo',
                  icon: Icons.monitor_weight,
                  keyboardType: TextInputType.number,
                  controller: kiloController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen Kilonuzu Giriniz';
                    }
                    return null;
                  },
                ),
                CustomTextWidget(
                  title: 'Şikayet',
                  icon: Icons.report,
                  keyboardType: TextInputType.text,
                  controller: sikayetController,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen Şikayetinizi Giriniz';
                    }
                    return null;
                  },
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

                const SizedBox(height: 16),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _loading
                            ? null
                            : () async {
                              if (!_formKey.currentState!.validate()) return;

                              final analysisResult = await _analyzeInputs();

                              try {
                                await collection.add({
                                  "boy": boyController.text.trim(),
                                  "yas": yasController.text.trim(),
                                  "kilo": kiloController.text.trim(),
                                  "sikayet": sikayetController.text.trim(),
                                  "sure": sureController.text.trim(),
                                  "ilac": ilacController.text.trim(),
                                  "cinsiyet": _cinsiyet ?? '',
                                  "analizSonucu": analysisResult,
                                  "tarih": FieldValue.serverTimestamp(),
                                });
                                print("Veri başarıyla eklendi.");
                              } catch (e) {
                                print("Hata oluştu: $e");
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => OverviewScreen(
                                        response: analysisResult,
                                      ),
                                ),
                              );
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
