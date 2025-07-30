class MedicalFormData {
  final String height;
  final String age;
  final String weight;
  final String gender;
  final String bloodType;
  final String smokeType;
  final String alcoholType;
  final String complaint;
  final String duration;
  final String medication;
  final String chronicDisease;

  MedicalFormData({
    required this.height,
    required this.age,
    required this.weight,
    required this.gender,
    required this.bloodType,
    required this.smokeType,
    required this.alcoholType,
    required this.complaint,
    required this.duration,
    required this.medication,
    required this.chronicDisease,
  });

  // Tüm form verilerini döndür
  Map<String, String> toMap() {
    return {
      'Boy': height,
      'Yaş': age,
      'Kilo': weight,
      'Cinsiyet': gender,
      'Kan Grubu': bloodType,
      'Sigara Kullanımı': smokeType,
      'Alkol Kullanımı': alcoholType,
      'Şikayet': complaint,
      'Şikayet Süresi': duration,
      'Mevcut İlaçlar': medication,
      'Kronik Rahatsızlık': chronicDisease,
    };
  }

  // Sadece kişisel profil bilgilerini döndür
  Map<String, String> toProfileMap() {
    return {
      'Boy': height,
      'Yaş': age,
      'Kilo': weight,
      'Cinsiyet': gender,
      'Kan Grubu': bloodType,
      'Sigara Kullanımı': smokeType,
      'Alkol Kullanımı': alcoholType,
      'Kronik Rahatsızlık': chronicDisease,
    };
  }

  // Sadece şikayet bilgilerini döndür
  Map<String, String> toComplaintMap() {
    return {
      'Şikayet': complaint,
      'Şikayet Süresi': duration,
      'Mevcut İlaçlar': medication,
    };
  }

  factory MedicalFormData.fromMap(Map<String, String> map) {
    return MedicalFormData(
      height: map['Boy'] ?? '',
      age: map['Yaş'] ?? '',
      weight: map['Kilo'] ?? '',
      gender: map['Cinsiyet'] ?? '',
      bloodType: map['Kan Grubu'] ?? '',
      smokeType: map['Sigara Kullanımı'] ?? '',
      alcoholType: map['Alkol Kullanımı'] ?? '',
      complaint: map['Şikayet'] ?? '',
      duration: map['Şikayet Süresi'] ?? '',
      medication: map['Mevcut İlaçlar'] ?? '',
      chronicDisease: map['Kronik Rahatsızlık'] ?? '',
    );
  }

  MedicalFormData copyWith({
    String? height,
    String? age,
    String? weight,
    String? gender,
    String? bloodType,
    String? smokeType,
    String? alcoholType,
    String? complaint,
    String? duration,
    String? medication,
    String? chronicDisease,
  }) {
    return MedicalFormData(
      height: height ?? this.height,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      smokeType: smokeType ?? this.smokeType,
      alcoholType: alcoholType ?? this.alcoholType,
      complaint: complaint ?? this.complaint,
      duration: duration ?? this.duration,
      medication: medication ?? this.medication,
      chronicDisease: chronicDisease ?? this.chronicDisease,
    );
  }
}
