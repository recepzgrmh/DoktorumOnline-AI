// lib/widgets/source_selection_bottom_sheet.dart
import 'package:flutter/material.dart';

class SelectionBottomSheet extends StatelessWidget {
  final VoidCallback onSelectPdf;
  final VoidCallback onSelectImage;

  const SelectionBottomSheet({
    super.key,
    required this.onSelectPdf,
    required this.onSelectImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Analiz Kaynağını Seçin',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.picture_as_pdf,
              color: Theme.of(context).primaryColor,
            ),
            title: const Text('PDF Dosyasından Seç'),
            onTap: () {
              Navigator.pop(context);
              onSelectPdf(); // Dışarıdan gelen fonksiyonu çağır
            },
          ),
          ListTile(
            leading: Icon(Icons.image, color: Theme.of(context).primaryColor),
            title: const Text('Resimden Analiz Et'),
            onTap: () {
              Navigator.pop(context);
              onSelectImage(); // Dışarıdan gelen fonksiyonu çağır
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }
}
