import 'package:flutter/material.dart';
import 'package:login_page/models/medical_form_data.dart';
import 'package:login_page/services/validation_service.dart';
import 'package:login_page/widgets/custom_text_widget.dart';

class ComplaintForm extends StatefulWidget {
  final TextEditingController sikayetController;
  final TextEditingController sureController;
  final TextEditingController ilacController;
  final Function(MedicalFormData) onFormChanged;
  final Map<String, String> userProfileData;

  const ComplaintForm({
    super.key,
    required this.sikayetController,
    required this.sureController,
    required this.ilacController,
    required this.onFormChanged,
    required this.userProfileData,
  });

  @override
  State<ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<ComplaintForm> {
  bool _isInfoVisible = true;
  double borderRadius = 15.0;
  void _notifyFormChanged() {
    final formData = MedicalFormData(
      height: widget.userProfileData['Boy'] ?? '',
      age: widget.userProfileData['Yaş'] ?? '',
      weight: widget.userProfileData['Kilo'] ?? '',
      gender: widget.userProfileData['Cinsiyet'] ?? '',
      bloodType: widget.userProfileData['Kan Grubu'] ?? '',
      complaint: widget.sikayetController.text,
      duration: widget.sureController.text,
      medication: widget.ilacController.text,
      chronicDisease: widget.userProfileData['Kronik Rahatsızlık'] ?? '',
    );

    widget.onFormChanged(formData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double borderRadius = 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //
        if (_isInfoVisible)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 8, 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: theme.iconTheme.size,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Mevcut sağlık bilgileriniz kullanılarak şikayetiniz analiz edilecektir. Lütfen sadece şikayetinizi ve süresini belirtiniz.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                // Kapatma butonu .
                IconButton(
                  icon: Icon(Icons.close, color: theme.colorScheme.primary),
                  onPressed: () {
                    setState(() {
                      _isInfoVisible = false;
                    });
                  },
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        Card(
          elevation: 3,
          shadowColor: Colors.teal.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),

          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: BorderSide(color: Colors.teal.withOpacity(0.2), width: 1.5),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: BorderSide(color: Colors.teal.withOpacity(0.2), width: 1.5),
            ),

            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,

            leading: Icon(Icons.person, color: Colors.teal, size: 20),
            title: Text(
              'Mevcut Sağlık Bilgileriniz',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildInfoChip(
                      'Boy: ${widget.userProfileData['Boy'] ?? 'N/A'} cm',
                      Icons.height,
                    ),
                    _buildInfoChip(
                      'Yaş: ${widget.userProfileData['Yaş'] ?? 'N/A'}',
                      Icons.calendar_today,
                    ),
                    _buildInfoChip(
                      'Kilo: ${widget.userProfileData['Kilo'] ?? 'N/A'} kg',
                      Icons.monitor_weight,
                    ),
                    _buildInfoChip(
                      'Cinsiyet: ${widget.userProfileData['Cinsiyet'] ?? 'N/A'}',
                      Icons.person,
                    ),
                    _buildInfoChip(
                      'Kan Grubu: ${widget.userProfileData['Kan Grubu'] ?? 'N/A'}',
                      Icons.bloodtype,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        CustomTextWidget(
          title: 'Şikayetiniz',
          icon: Icons.medical_services,
          autofocus: true,
          controller: widget.sikayetController,
          maxLines: 3,
          validator: ValidationService.validateComplaint,
          onChanged: (_) => _notifyFormChanged(),
        ),
        CustomTextWidget(
          title: 'Şikayet Süresi',
          icon: Icons.timer,
          controller: widget.sureController,
          validator: ValidationService.validateDuration,
          onChanged: (_) => _notifyFormChanged(),
        ),
        CustomTextWidget(
          title: 'Mevcut İlaçlar (Opsiyonel)',
          icon: Icons.medication,
          controller: widget.ilacController,
          maxLines: 2,
          validator: ValidationService.validateMedication,
          onChanged: (_) => _notifyFormChanged(),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    final theme = Theme.of(context);

    return Chip(
      backgroundColor: theme.colorScheme.surfaceVariant,

      side: BorderSide(color: Colors.teal.withOpacity(0.2), width: 1.5),

      avatar: Icon(icon, size: 18, color: Colors.teal),
      label: Text(text),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
      ),

      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    );
  }
}
