import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:login_page/services/validation_service.dart';
import 'package:login_page/widgets/custom_dropdown_widget.dart';
import 'package:login_page/widgets/custom_text_widget.dart';

class ProfileForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController boyController;
  final TextEditingController yasController;
  final TextEditingController kiloController;
  final String? cinsiyet;
  final String? kanGrubu;
  final Function(String?) onCinsiyetChanged;
  final Function(String?) onKanGrubuChanged;

  const ProfileForm({
    super.key,
    required this.nameController,
    required this.boyController,
    required this.yasController,
    required this.kiloController,
    required this.cinsiyet,
    required this.kanGrubu,
    required this.onCinsiyetChanged,
    required this.onKanGrubuChanged,
  });

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
                  Icons.person_outline,
                  color: theme.colorScheme.primary,
                  size: theme.iconTheme.size,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'update_profile_warning'.tr(),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        CustomTextWidget(
          title: 'profile_name'.tr(),
          icon: Icons.person,
          controller: nameController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Profil adı gereklidir';
            }
            if (value.length < 2) {
              return 'Profil adı en az 2 karakter olmalıdır';
            }
            return null;
          },
        ),

        CustomTextWidget(
          title: 'medicalForm.heightLabel'.tr(),
          icon: Icons.height,
          controller: boyController,
          keyboardType: TextInputType.number,
          validator: ValidationService.validateHeight,
        ),

        CustomTextWidget(
          title: 'medicalForm.ageLabel'.tr(),
          icon: Icons.calendar_today,
          controller: yasController,
          keyboardType: TextInputType.number,
          validator: ValidationService.validateAge,
        ),

        CustomTextWidget(
          title: 'medicalForm.weightLabel'.tr(),
          icon: Icons.monitor_weight,
          controller: kiloController,
          keyboardType: TextInputType.number,
          validator: ValidationService.validateWeight,
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
          onChanged: onCinsiyetChanged,
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
          onChanged: onKanGrubuChanged,
          validator: ValidationService.validateBloodType,
        ),
      ],
    );
  }
}
