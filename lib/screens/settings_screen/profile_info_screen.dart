import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_page/services/auth_service.dart';
import 'package:login_page/widgets/custom_button.dart';

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  User? _user;
  bool _hasPasswordAuth = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _hasPasswordAuth = _user!.providerData.any(
        (provider) => provider.providerId == 'password',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 100),
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.blue.shade100,
                child: AuthService().getProfileAvatar(radius: 48),
              ),
              const SizedBox(height: 20),
              Text(
                _user!.displayName ?? 'İsim Belirtilmemiş',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _user!.email ?? 'E-posta Yok',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const ProfileInfoRow(
                      label: 'Telefon',
                      value: '+90 555 555 55 55',
                    ),
                    const Divider(),
                    ProfileInfoRow(
                      label: 'Kayıt Olma Tarihi',
                      value:
                          '${_user!.metadata.creationTime?.day}.${_user!.metadata.creationTime?.month}.${_user!.metadata.creationTime?.year}',
                    ),
                    const Divider(),
                    const ProfileInfoRow(
                      label: 'Cinsiyet',
                      value: 'Belirtilmedi',
                    ),
                    const Divider(),

                    if (_hasPasswordAuth)
                      const ProfileInfoRow(
                        label: 'Şifre',
                        value: 'Şifreni Değiştir',
                        isButton: true,
                      )
                    else
                      const ProfileInfoRow(
                        label: 'Şifre',
                        value: 'Şifre Belirle',
                        isButton: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: 'Bilgileri Düzenle',
                  onPressed: () {},
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isButton;

  const ProfileInfoRow({
    required this.label,
    required this.value,
    super.key,
    this.isButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),

          if (isButton)
            TextButton(
              onPressed: () {
                print('$value tıklandı!');
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}
