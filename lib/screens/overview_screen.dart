import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:login_page/widgets/custom_text_widget.dart';

class OverviewScreen extends StatelessWidget {
  final String response;

  const OverviewScreen({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    // Gelen response değerini konsola yazdır
    print('OverviewScreen response: $response');

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Chat', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Üst kısım kaydırılabilir
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: Colors.teal.shade50,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Durum Özeti',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(response),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Alt sabit buton
            const SizedBox(height: 20),
            CustomTextWidget(
              icon: Icons.send,
              title: 'Sohbete devam etmek için tıklayın',
              controller: TextEditingController(),
            ),
          ],
        ),
      ),
    );
  }
}
