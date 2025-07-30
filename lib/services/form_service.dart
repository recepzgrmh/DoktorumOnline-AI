import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FormService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı profil bilgilerini kaydet
  Future<void> saveUserProfile({
    required Map<String, String> profileData,
  }) async {
    final uid = _auth.currentUser!.uid;
    final userDoc = _firestore.collection('users').doc(uid);

    // Mevcut kullanıcı verilerini al
    final currentData = await userDoc.get();
    final profiles =
        currentData.exists
            ? (currentData.data()?['profiles'] as List<dynamic>? ?? [])
            : [];

    if (profiles.isNotEmpty) {
      // Profil sistemi varsa, aktif profili güncelle
      final updatedProfiles =
          profiles.map((profile) {
            final profileMap = Map<String, dynamic>.from(profile);
            if (profileMap['isActive'] == true) {
              return {
                ...profileMap,
                'height':
                    int.tryParse(profileData['Boy'] ?? '') ??
                    profileMap['height'],
                'age':
                    int.tryParse(profileData['Yaş'] ?? '') ?? profileMap['age'],
                'weight':
                    double.tryParse(profileData['Kilo'] ?? '') ??
                    profileMap['weight'],
                'gender': profileData['Cinsiyet'] ?? profileMap['gender'],
                'bloodType':
                    profileData['Kan Grubu'] ?? profileMap['bloodType'],
                'smokeType':
                    profileData['Sigara Kullanımı'] ?? profileMap['smokeType'],
                'alcoholType':
                    profileData['Alkol Kullanımı'] ?? profileMap['alcoholType'],
                'chronicIllness':
                    profileData['Kronik Rahatsızlık'] ??
                    profileMap['chronicIllness'],
                'updatedAt': DateTime.now().toIso8601String(),
              };
            }
            return profile;
          }).toList();

      await userDoc.set({
        'profiles': updatedProfiles,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      // Eski yapıyı kullan (geriye uyumluluk için)
      await userDoc.set({
        'boy': profileData['Boy'],
        'yas': profileData['Yaş'],
        'kilo': profileData['Kilo'],
        'cinsiyet': profileData['Cinsiyet'],
        'kan_grubu': profileData['Kan Grubu'],
        'sigara': profileData['Sigara Kullanımı'],
        'alkol': profileData['Alkol Kullanımı'],
        'kronik_rahatsizlik': profileData['Kronik Rahatsızlık'],
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // Sadece şikayet bilgilerini kaydet
  Future<String> saveComplaint({
    required Map<String, String> complaintData,
    required String complaintId,
  }) async {
    final uid = _auth.currentUser!.uid;
    final complaintDoc = _firestore
        .collection('users')
        .doc(uid)
        .collection('complaints')
        .doc(complaintId);

    await complaintDoc.set({
      'sikayet': complaintData['Şikayet'],
      'sure': complaintData['Şikayet Süresi'],
      'ilac': complaintData['Mevcut İlaçlar'],
      'createdAt': FieldValue.serverTimestamp(),
      'lastAnalyzed': FieldValue.serverTimestamp(),
    });

    return complaintId;
  }

  // Şikayet ve kullanıcı profil bilgilerini birlikte kaydet
  Future<String> saveComplaintWithProfile({
    required Map<String, String> formData,
    required String complaintId,
  }) async {
    // Önce kullanıcı profil bilgilerini kaydet
    await saveUserProfile(
      profileData: {
        'Boy': formData['Boy'] ?? '',
        'Yaş': formData['Yaş'] ?? '',
        'Kilo': formData['Kilo'] ?? '',
        'Cinsiyet': formData['Cinsiyet'] ?? '',
        'Kan Grubu': formData['Kan Grubu'] ?? '',
        'Sigara Kullanımı': formData['Sigara Kullanımı'] ?? '',
        'Alkol Kullanımı': formData['Alkol Kullanımı'] ?? '',
        'Kronik Rahatsızlık': formData['Kronik Rahatsızlık'] ?? '',
      },
    );

    // Sonra sadece şikayet bilgilerini kaydet
    await saveComplaint(
      complaintData: {
        'Şikayet': formData['Şikayet'] ?? '',
        'Şikayet Süresi': formData['Şikayet Süresi'] ?? '',
        'Mevcut İlaçlar': formData['Mevcut İlaçlar'] ?? '',
      },
      complaintId: complaintId,
    );

    return complaintId;
  }

  Future<void> saveMessage({
    required String complaintId,
    required String text,
    required String senderId,
  }) async {
    final uid = _auth.currentUser!.uid;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('complaints')
        .doc(complaintId)
        .collection('messages')
        .add({
          'text': text,
          'senderId': senderId,
          'sentAt': FieldValue.serverTimestamp(),
        });
  }

  Future<List<Map<String, dynamic>>> getMessageHistory(
    String complaintId,
  ) async {
    final uid = _auth.currentUser!.uid;
    final snapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('complaints')
            .doc(complaintId)
            .collection('messages')
            .orderBy('sentAt')
            .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<Map<String, String>> getUserProfileData() async {
    final uid = _auth.currentUser!.uid;
    final userDoc = await _firestore.collection('users').doc(uid).get();

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;

      // Önce aktif profil bilgilerini kontrol et
      final profiles = data['profiles'] as List<dynamic>? ?? [];
      final activeProfile = profiles.firstWhere(
        (profile) => profile['isActive'] == true,
        orElse: () => {},
      );

      if (activeProfile.isNotEmpty) {
        // Aktif profil varsa onun bilgilerini kullan
        return {
          'Boy': activeProfile['height']?.toString() ?? '',
          'Yaş': activeProfile['age']?.toString() ?? '',
          'Kilo': activeProfile['weight']?.toString() ?? '',
          'Cinsiyet': activeProfile['gender']?.toString() ?? '',
          'Kan Grubu': activeProfile['bloodType']?.toString() ?? '',
          'Sigara Kullanımı': activeProfile['smokeType']?.toString() ?? '',
          'Alkol Kullanımı': activeProfile['alcoholType']?.toString() ?? '',
          'Kronik Rahatsızlık':
              activeProfile['chronicIllness']?.toString() ?? '',
        };
      } else {
        // Eski yapıyı kullan (geriye uyumluluk için)
        return {
          'Boy': data['boy']?.toString() ?? '',
          'Yaş': data['yas']?.toString() ?? '',
          'Kilo': data['kilo']?.toString() ?? '',
          'Cinsiyet': data['cinsiyet']?.toString() ?? '',
          'Kan Grubu': data['kan_grubu']?.toString() ?? '',
          'Sigara Kullanımı': data['sigara']?.toString() ?? '',
          'Alkol Kullanımı': data['alkol']?.toString() ?? '',
          'Kronik Rahatsızlık': data['kronik_rahatsizlik']?.toString() ?? '',
        };
      }
    }

    return {};
  }

  // Şikayet detaylarını kullanıcı profil bilgileriyle birlikte getir
  Future<Map<String, dynamic>> getComplaintWithProfile(
    String complaintId,
  ) async {
    final uid = _auth.currentUser!.uid;

    // Kullanıcı profil bilgilerini al
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};

    // Şikayet bilgilerini al
    final complaintDoc =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('complaints')
            .doc(complaintId)
            .get();
    final complaintData = complaintDoc.data() ?? {};

    // Birleştir
    return {...userData, ...complaintData};
  }
}
