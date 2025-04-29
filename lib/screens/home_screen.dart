import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_page/screens/opening.dart';
import 'package:login_page/widgets/input_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => Opening()));
  }

  String _gender = 'Seçiniz';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'DoktorumOnline AI',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Yaşınız*:
            InputField(label: 'Yaşınız*:', keyboardType: TextInputType.number),
            const SizedBox(height: 16),

            // Cinsiyetiniz*:
            DropdownButtonFormField<String>(
              value: _gender,
              onChanged: (v) => setState(() => _gender = v!),
              decoration: InputDecoration(
                floatingLabelBehavior: FloatingLabelBehavior.always,
                labelText: 'Cinsiyetiniz*:',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
              ),
              items:
                  <String>['Seçiniz', 'Erkek', 'Kadın', 'Diğer']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
            ),
            const SizedBox(height: 16),

            // Boyunuz (cm)*:
            InputField(
              label: 'Boyunuz (cm)*:',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Kilonuz (kg)*:
            InputField(
              label: 'Kilonuz (kg)*:',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Sorununuz*:
            InputField(label: 'Sorununuz*:', maxLines: 3),
            const SizedBox(height: 16),

            // Şikayet Süresi (opsiyonel):
            InputField(label: 'Şikayet Süresi (opsiyonel):'),
            const SizedBox(height: 16),

            // Mevcut İlaçlar (opsiyonel):
            InputField(label: 'Mevcut İlaçlar (opsiyonel):', maxLines: 2),
            const SizedBox(height: 24),

            // Analiz Et Butonu
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 3,
                ),
                child: const Text('Analiz Et'),
              ),
            ),

            SizedBox(height: 15),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 3,
                ),
                child: const Text('log out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
