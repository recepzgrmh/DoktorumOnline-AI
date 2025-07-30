import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_page/screens/opening.dart';
import 'package:login_page/screens/settings_screen/about_screen.dart';
import 'package:login_page/screens/settings_screen/dialog_utils.dart';
import 'package:login_page/screens/settings_screen/profile_info_screen.dart';
import 'package:login_page/screens/settings_screen/support_screen.dart';

import 'package:login_page/screens/settings_screen/language_screen.dart';
import 'package:login_page/widgets/custom_button.dart';

import 'package:login_page/widgets/custom_page_route.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _utils = DialogUtils();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          'settings'.tr(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
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
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'profile_info'.tr(),
                  subtitle: 'profile_info_subtitle'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      CustomPageRoute(
                        child: ProfileInfoScreen(),
                        name: 'profile_info_screen',
                      ),
                    );
                  },
                ),

                _buildMenuItem(
                  icon: Icons.language_outlined,
                  title: 'language_and_region'.tr(),
                  subtitle: 'language_and_region_subtitle'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      CustomPageRoute(
                        child: LanguageScreen(),
                        name: 'language_screen',
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'support'.tr(),
                  subtitle: 'support_subtitle'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      CustomPageRoute(
                        child: SupportScreen(),
                        name: 'support_screen',
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: 'about'.tr(),
                  subtitle: 'about_subtitle'.tr(),
                  onTap: () {
                    Navigator.push(
                      context,
                      CustomPageRoute(
                        child: AboutScreen(),
                        name: 'about_Screen',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Spacer(),
          Padding(
            padding: EdgeInsets.all(20),
            child: _buildLogoutButton(context),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 30),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomButton(
        icon: Icon(Icons.logout, color: Colors.white),
        label: 'logout'.tr(),
        onPressed: () {
          _utils.showConfirmationDialog(
            context: context,
            title: 'logout'.tr(),
            content: 'logout_content'.tr(),
            icon: Icons.logout,
            onConfirm: signOut,
          );
        },
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => Opening()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Çıkış hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('logout_error'.tr(args: [e.toString()]))),
        );
      }
    }
  }
}
