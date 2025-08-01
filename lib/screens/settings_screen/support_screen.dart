import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:login_page/widgets/custom_button.dart';
import 'package:login_page/widgets/custom_text_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// Firestore'a yazıp geri bildirim kaydeder
  Future<void> _sendFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final pkgInfo = await PackageInfo.fromPlatform();

      await FirebaseFirestore.instance.collection('feedback').add({
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'userId': user?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'appVersion': pkgInfo.version,
      });

      _formKey.currentState!.reset();
      _subjectController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('feedback_success'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('support'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.blue,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'feedback_title'.tr(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'feedback_description'.tr(),
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  CustomTextWidget(
                    title: 'subject'.tr(),
                    icon: Icons.subject,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'subject_required'.tr();
                      }
                      return null;
                    },
                    controller: _subjectController,
                  ),

                  CustomTextWidget(
                    title: 'message'.tr(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'message_required'.tr();
                      }
                      return null;
                    },
                    maxLines: 4,
                    icon: Icons.message,
                    controller: _messageController,
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      label: _sending ? 'sending'.tr() : 'send'.tr(),
                      onPressed: () {
                        _sending ? null : _sendFeedback();
                      },
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
