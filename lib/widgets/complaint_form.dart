import 'package:flutter/material.dart';
import 'package:login_page/models/medical_form_data.dart';
import 'package:login_page/services/validation_service.dart';
import 'package:login_page/theme/app_theme.dart';
import 'package:login_page/widgets/custom_text_widget.dart';

class ComplaintForm extends StatelessWidget {
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

  void _notifyFormChanged() {
    final formData = MedicalFormData(
      height: userProfileData['Boy'] ?? '',
      age: userProfileData['Yaş'] ?? '',
      weight: userProfileData['Kilo'] ?? '',
      gender: userProfileData['Cinsiyet'] ?? '',
      bloodType: userProfileData['Kan Grubu'] ?? '',
      complaint: sikayetController.text,
      duration: sureController.text,
      medication: ilacController.text,
      chronicDisease: userProfileData['Kronik Rahatsızlık'] ?? '',
    );
    onFormChanged(formData);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double borderRadius = 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
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
              Expanded(
                child: Text(
                  'Mevcut sağlık bilgileriniz kullanılarak şikayetiniz analiz edilecektir. Lütfen sadece şikayetinizi ve süresini belirtiniz.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Kullanıcı profil bilgilerini gösteren kart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: theme.colorScheme.secondary.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: theme.colorScheme.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mevcut Sağlık Bilgileriniz',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    'Boy: ${userProfileData['Boy'] ?? 'N/A'} cm',
                    Icons.height,
                  ),
                  _buildInfoChip(
                    'Yaş: ${userProfileData['Yaş'] ?? 'N/A'}',
                    Icons.calendar_today,
                  ),
                  _buildInfoChip(
                    'Kilo: ${userProfileData['Kilo'] ?? 'N/A'} kg',
                    Icons.monitor_weight,
                  ),
                  _buildInfoChip(
                    'Cinsiyet: ${userProfileData['Cinsiyet'] ?? 'N/A'}',
                    Icons.person,
                  ),
                  _buildInfoChip(
                    'Kan Grubu: ${userProfileData['Kan Grubu'] ?? 'N/A'}',
                    Icons.bloodtype,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        CustomTextWidget(
          title: 'Şikayetiniz',
          icon: Icons.medical_services,
          controller: sikayetController,
          maxLines: 3,
          validator: ValidationService.validateComplaint,
          onChanged: (_) => _notifyFormChanged(),
        ),
        CustomTextWidget(
          title: 'Şikayet Süresi',
          icon: Icons.timer,
          controller: sureController,
          validator: ValidationService.validateDuration,
          onChanged: (_) => _notifyFormChanged(),
        ),
        CustomTextWidget(
          title: 'Mevcut İlaçlar (Opsiyonel)',
          icon: Icons.medication,
          controller: ilacController,
          maxLines: 2,
          validator: ValidationService.validateMedication,
          onChanged: (_) => _notifyFormChanged(),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
