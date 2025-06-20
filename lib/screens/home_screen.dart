// lib/screens/home_screen.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_page/models/medical_form_data.dart';
import 'package:login_page/screens/opening.dart';
import 'package:login_page/screens/overview_screen.dart';
import 'package:login_page/services/form_service.dart';
import 'package:login_page/services/openai_service.dart';
import 'package:login_page/widgets/custom_appBar.dart';
import 'package:login_page/widgets/custom_button.dart';
import 'package:login_page/widgets/loading_widget.dart';
import 'package:login_page/widgets/medical_form.dart';
import 'package:login_page/widgets/my_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = OpenAIService();
  final _formService = FormService();
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
  MedicalFormData? _formData;

  bool _loading = false;
  final _uid = FirebaseAuth.instance.currentUser!.uid;

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
    if (_formData == null) return;

    setState(() => _loading = true);

    try {
      final complaintDoc =
          FirebaseFirestore.instance
              .collection('users')
              .doc(_uid)
              .collection('complaints')
              .doc();
      final complaintId = complaintDoc.id;

      await _formService.saveComplaint(
        inputs: _formData!.toMap(),
        complaintId: complaintId,
      );

      final parts = await _service.getFollowUpQuestions(_formData!.toMap());

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
                ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Başlatma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Başlatma hatası: $e')));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'DoktorumOnline AI'),
      drawer: const MyDrawer(),
      body:
          _loading
              ? const LoadingWidget(message: "Şikayetiniz işleniyor...")
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        MedicalForm(
                          boyController: boyController,
                          yasController: yasController,
                          kiloController: kiloController,
                          sikayetController: sikayetController,
                          sureController: sureController,
                          ilacController: ilacController,
                          illnessController: illnessController,
                          cinsiyet: _cinsiyet,
                          kanGrubu: _kanGrubu,
                          onCinsiyetChanged: (value) {
                            setState(() => _cinsiyet = value);
                          },
                          onKanGrubuChanged: (value) {
                            setState(() => _kanGrubu = value);
                          },
                          onFormChanged: (formData) {
                            setState(() => _formData = formData);
                          },
                        ),

                        const SizedBox(height: 16),
                        CustomButton(
                          label: 'Şikayeti Başlat',
                          onPressed: _startFollowUp,
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          icon: const Icon(Icons.medical_services),
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
}
