import 'package:flutter/material.dart';
import 'package:login_page/constants/app_constants.dart';
import 'package:login_page/models/medical_form_data.dart';
import 'package:login_page/services/validation_service.dart';
import 'package:login_page/theme/app_theme.dart';
import 'package:login_page/widgets/custom_text_widget.dart';

class MedicalForm extends StatelessWidget {
  final TextEditingController boyController;
  final TextEditingController yasController;
  final TextEditingController kiloController;
  final TextEditingController sikayetController;
  final TextEditingController sureController;
  final TextEditingController ilacController;
  final TextEditingController illnessController;
  final String? cinsiyet;
  final String? kanGrubu;
  final Function(String?) onCinsiyetChanged;
  final Function(String?) onKanGrubuChanged;
  final Function(MedicalFormData) onFormChanged;

  const MedicalForm({
    Key? key,
    required this.boyController,
    required this.yasController,
    required this.kiloController,
    required this.sikayetController,
    required this.sureController,
    required this.ilacController,
    required this.illnessController,
    required this.cinsiyet,
    required this.kanGrubu,
    required this.onCinsiyetChanged,
    required this.onKanGrubuChanged,
    required this.onFormChanged,
  }) : super(key: key);

  void _notifyFormChanged() {
    final formData = MedicalFormData(
      height: boyController.text,
      age: yasController.text,
      weight: kiloController.text,
      gender: cinsiyet ?? '',
      bloodType: kanGrubu ?? '',
      complaint: sikayetController.text,
      duration: sureController.text,
      medication: ilacController.text,
      chronicDisease: illnessController.text,
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
                  AppConstants.formInfoMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CustomTextWidget(
          title: AppConstants.heightLabel,
          icon: Icons.height,
          controller: boyController,
          keyboardType: TextInputType.number,
          validator: ValidationService.validateHeight,
          onChanged: (_) => _notifyFormChanged(),
        ),
        CustomTextWidget(
          title: AppConstants.ageLabel,
          icon: Icons.calendar_today,
          controller: yasController,
          keyboardType: TextInputType.number,
          validator: ValidationService.validateAge,
          onChanged: (_) => _notifyFormChanged(),
        ),
        CustomTextWidget(
          title: AppConstants.weightLabel,
          icon: Icons.monitor_weight,
          controller: kiloController,
          keyboardType: TextInputType.number,
          validator: ValidationService.validateWeight,
          onChanged: (_) => _notifyFormChanged(),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: cinsiyet,
          decoration: InputDecoration(
            labelText: AppConstants.genderLabel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
            DropdownMenuItem(value: 'Kadın', child: Text('Kadın')),
          ],
          onChanged: (value) {
            onCinsiyetChanged(value);
            _notifyFormChanged();
          },
          validator: ValidationService.validateGender,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: kanGrubu,
          decoration: InputDecoration(
            labelText: AppConstants.bloodTypeLabel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'A Rh+', child: Text('A Rh+')),
            DropdownMenuItem(value: 'A Rh-', child: Text('A Rh-')),
            DropdownMenuItem(value: 'B Rh+', child: Text('B Rh+')),
            DropdownMenuItem(value: 'B Rh-', child: Text('B Rh-')),
            DropdownMenuItem(value: 'AB Rh+', child: Text('AB Rh+')),
            DropdownMenuItem(value: 'AB Rh-', child: Text('AB Rh-')),
            DropdownMenuItem(value: '0 Rh+', child: Text('0 Rh+')),
            DropdownMenuItem(value: '0 Rh-', child: Text('0 Rh-')),
          ],
          onChanged: (value) {
            onKanGrubuChanged(value);
            _notifyFormChanged();
          },
          validator: ValidationService.validateBloodType,
        ),
        const SizedBox(height: 16),
        CustomTextWidget(
          title: AppConstants.complaintLabel,
          icon: Icons.medical_services,
          controller: sikayetController,
          maxLines: 3,
          validator: ValidationService.validateComplaint,
          onChanged: (_) => _notifyFormChanged(),
        ),
        CustomTextWidget(
          title: AppConstants.durationLabel,
          icon: Icons.timer,
          controller: sureController,
          validator: ValidationService.validateDuration,
          onChanged: (_) => _notifyFormChanged(),
        ),
        CustomTextWidget(
          title: AppConstants.medicationLabel,
          icon: Icons.medication,
          controller: ilacController,
          maxLines: 2,
          validator: ValidationService.validateMedication,
          onChanged: (_) => _notifyFormChanged(),
        ),
        CustomTextWidget(
          title: AppConstants.chronicDiseaseLabel,
          icon: Icons.health_and_safety,
          controller: illnessController,
          maxLines: 2,
          validator: ValidationService.validateChronicDisease,
          onChanged: (_) => _notifyFormChanged(),
        ),
      ],
    );
  }
}
