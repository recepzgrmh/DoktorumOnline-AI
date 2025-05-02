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

  final TextEditingController boyController = TextEditingController();
  final TextEditingController yasController = TextEditingController();
  final TextEditingController kiloController = TextEditingController();
  final TextEditingController sikayetController = TextEditingController();
  final TextEditingController sureController = TextEditingController();
  final TextEditingController ilacController = TextEditingController();

  bool _loading = false;

  // Kullanıcının girmiş olduğu verileri saklamak için problem adlı collection oluşturduk
  final collection = FirebaseFirestore.instance.collection("problem");

  @override
  void dispose() {
    // kullanıcıdan verileri almak için controller ekledik
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

  // çıkış yapma fonksiyonu
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

      // Soldan Kayan Menü
      drawer: const MyDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              CustomTextWidget(
                title: 'Boy',
                icon: Icons.straighten,
                keyboardType: TextInputType.number,
                controller: boyController,
              ),
              CustomTextWidget(
                title: 'Yaş',
                icon: Icons.cake,
                keyboardType: TextInputType.number,
                controller: yasController,
              ),
              CustomTextWidget(
                title: 'Kilo',
                icon: Icons.monitor_weight,
                keyboardType: TextInputType.number,
                controller: kiloController,
              ),
              CustomTextWidget(
                title: 'Şikayet',
                icon: Icons.report,
                keyboardType: TextInputType.text,
                controller: sikayetController,
                maxLines: 3,
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
                            final analysisResult = await _analyzeInputs();

                            try {
                              await collection.add({
                                "boy": boyController.text.trim(),
                                "yas": yasController.text.trim(),
                                "kilo": kiloController.text.trim(),
                                "sikayet": sikayetController.text.trim(),
                                "sure": sureController.text.trim(),
                                "ilac": ilacController.text.trim(),
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
    );
  }
}
