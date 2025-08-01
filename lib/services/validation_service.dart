import 'package:easy_localization/easy_localization.dart';

class ValidationService {
  static String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation_enter_height'.tr();
    }
    final height = double.tryParse(value);
    if (height == null || height <= 0 || height > 300) {
      return 'validation_invalid_height'.tr();
    }
    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation_enter_age'.tr();
    }
    final age = int.tryParse(value);
    if (age == null || age <= 0 || age > 120) {
      return 'validation_enter_age'.tr();
    }
    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation_enter_weight'.tr();
    }
    final weight = double.tryParse(value);
    if (weight == null || weight <= 0 || weight > 500) {
      return 'validation_inavlid_weight';
    }
    return null;
  }

  static String? validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation_select_gender'.tr();
    }
    return null;
  }

  static String? validateBloodType(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation_select_blood_type'.tr();
    }
    return null;
  }

  static String? validateSmokeType(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation_select_smoke_type'.tr();
    }
    return null;
  }

  static String? validateAlcoholType(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation_select_alcohol_type'.tr();
    }
    return null;
  }

  static String? validateComplaint(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation_enter_complaint'.tr();
    }
    if (value.length < 10) {
      return 'validation_complaint_short'.tr();
    }
    return null;
  }

  static String? validateDuration(String? value) {
    if (value == null || value.isEmpty) {
      return "validation_enter_duration".tr();
    }

    return null;
  }

  static String? validateMedication(String? value) {
    if (value != null && value.isNotEmpty && value.length < 3) {
      return 'validation_invalid_drug'.tr();
    }
    return null;
  }

  static String? validateChronicDisease(String? value) {
    if (value != null && value.isNotEmpty && value.length < 3) {
      return 'validation_invalid_cronical'.tr();
    }
    return null;
  }
}
