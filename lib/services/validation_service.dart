class ValidationService {
  static String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen boyunuzu giriniz';
    }
    final height = double.tryParse(value);
    if (height == null || height <= 0 || height > 300) {
      return 'Geçerli bir boy değeri giriniz (1-300 cm)';
    }
    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen yaşınızı giriniz';
    }
    final age = int.tryParse(value);
    if (age == null || age <= 0 || age > 120) {
      return 'Geçerli bir yaş giriniz (1-120)';
    }
    return null;
  }

  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen kilonuzu giriniz';
    }
    final weight = double.tryParse(value);
    if (weight == null || weight <= 0 || weight > 500) {
      return 'Geçerli bir kilo değeri giriniz (1-500 kg)';
    }
    return null;
  }

  static String? validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen cinsiyetinizi seçiniz';
    }
    return null;
  }

  static String? validateBloodType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen kan grubunuzu seçiniz';
    }
    return null;
  }

  static String? validateComplaint(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen şikayetinizi giriniz';
    }
    if (value.length < 10) {
      return 'Lütfen şikayetinizi daha detaylı açıklayınız (en az 10 karakter)';
    }
    return null;
  }

  static String? validateDuration(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen şikayet sürenizi giriniz';
    }
    return null;
  }

  static String? validateMedication(String? value) {
    if (value != null && value.isNotEmpty && value.length < 3) {
      return 'Lütfen ilaç bilgisini daha detaylı giriniz';
    }
    return null;
  }

  static String? validateChronicDisease(String? value) {
    if (value != null && value.isNotEmpty && value.length < 3) {
      return 'Lütfen kronik rahatsızlık bilgisini daha detaylı giriniz';
    }
    return null;
  }
}
