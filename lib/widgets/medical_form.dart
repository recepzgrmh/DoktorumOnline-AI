import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:login_page/models/medical_form_data.dart';
import 'package:login_page/services/validation_service.dart';
import 'package:login_page/widgets/custom_dropdown_widget.dart';
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
  final String? sigara;
  final String? alkol;
  final Function(String?) onCinsiyetChanged;
  final Function(String?) onKanGrubuChanged;
  final Function(String?) onSigaraChanged;
  final Function(String?) onAlkolChanged;
  final Function(MedicalFormData) onFormChanged;

  const MedicalForm({
    super.key,
    required this.boyController,
    required this.yasController,
    required this.kiloController,
    required this.sikayetController,
    required this.sureController,
    required this.ilacController,
    required this.illnessController,
    required this.cinsiyet,
    required this.kanGrubu,
    required this.sigara,
    required this.alkol,
    required this.onCinsiyetChanged,
    required this.onKanGrubuChanged,
    required this.onSigaraChanged,
    required this.onAlkolChanged,
    required this.onFormChanged,
  });

  void _notifyFormChanged() {
    final formData = MedicalFormData(
      height: boyController.text,
      age: yasController.text,
      weight: kiloController.text,
      gender: cinsiyet ?? '',
      bloodType: kanGrubu ?? '',
      smokeType: sigara ?? '',
      alcoholType: alkol ?? '',
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
                  'medicalForm.infoText'.tr(),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CustomTextWidget(
          title: 'medicalForm.heightLabel'.tr(),
          icon: Icons.height,
          controller: boyController,
          keyboardType: TextInputType.number,
          validator: ValidationService.validateHeight,
          onChanged: (_) => _notifyFormChanged(),
        ),
        CustomTextWidget(
          title: 'medicalForm.ageLabel'.tr(),
          icon: Icons.calendar_today,
          controller: yasController,
          keyboardType: TextInputType.number,
          validator: ValidationService.validateAge,
          onChanged: (_) => _notifyFormChanged(),
        ),
        CustomTextWidget(
          title: 'medicalForm.weightLabel'.tr(),
          icon: Icons.monitor_weight,
          controller: kiloController,
          keyboardType: TextInputType.number,
          validator: ValidationService.validateWeight,
          onChanged: (_) => _notifyFormChanged(),
        ),

        CustomDropdownWidget<String>(
          label: 'medicalForm.genderLabel'.tr(),
          icon: Icons.person,
          value: cinsiyet,
          items: [
            DropdownMenuItem(
              value: 'Erkek',
              child: Text('medicalForm.genderMale'.tr()),
            ),
            DropdownMenuItem(
              value: 'Kadın',
              child: Text('medicalForm.genderFemale'.tr()),
            ),
          ],
          onChanged: (value) {
            onCinsiyetChanged(value);
            _notifyFormChanged();
          },
          validator: ValidationService.validateGender,
        ),

        CustomDropdownWidget<String>(
          label: 'medicalForm.bloodTypeLabel'.tr(),
          icon: Icons.bloodtype,
          value: kanGrubu,
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

        CustomDropdownWidget<String>(
          label: 'Sigara Kullanımı',
          icon: Icons.smoking_rooms_rounded,
          value: sigara,
          items: const [
            DropdownMenuItem(value: 'İçmiyorum', child: Text('İçmiyorum')),
            DropdownMenuItem(value: 'Bıraktım', child: Text('Bıraktım')),
            DropdownMenuItem(
              value: 'Nadiren İçiyorum',
              child: Text('Nadiren İçiyorum'),
            ),

            DropdownMenuItem(
              value: 'Düzenli İçiyorum',
              child: Text('Düzenli İçiyorum'),
            ),
          ],
          onChanged: (value) {
            onSigaraChanged(value);
            _notifyFormChanged();
          },
          validator: ValidationService.validateSmokeType,
        ),

        CustomDropdownWidget<String>(
          label: 'alcohol_label'.tr(),
          icon: Icons.local_bar_outlined,
          value: alkol,
          items: [
            DropdownMenuItem(value: 'İçmiyorum', child: Text('none'.tr())),
            DropdownMenuItem(value: 'Bıraktım', child: Text('quit'.tr())),
            DropdownMenuItem(
              value: 'Nadiren İçiyorum',
              child: Text('occasionally'.tr()),
            ),
            DropdownMenuItem(
              value: 'Düzenli İçiyorum',
              child: Text('regularly'.tr()),
            ),
          ],
          onChanged: (value) {
            onAlkolChanged(value);
            _notifyFormChanged();
          },
          validator: ValidationService.validateAlcoholType,
        ),

        CustomTextWidget(
          title: 'medicalForm.complaintLabel'.tr(),
          icon: Icons.medical_services,
          controller: sikayetController,
          maxLines: 3,
          validator: ValidationService.validateComplaint,
          onChanged: (_) => _notifyFormChanged(),
        ),
        CustomTextWidget(
          title: 'medicalForm.durationLabel'.tr(),
          icon: Icons.timer,
          controller: sureController,
          validator: ValidationService.validateDuration,
          onChanged: (_) => _notifyFormChanged(),
        ),
        CustomTextWidget(
          title: 'medicalForm.medicationLabel'.tr(),
          icon: Icons.medication,
          controller: ilacController,
          maxLines: 2,
          validator: ValidationService.validateMedication,
          onChanged: (_) => _notifyFormChanged(),
        ),
        CustomTextWidget(
          title: 'medicalForm.chronicDiseaseLabel'.tr(),
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
