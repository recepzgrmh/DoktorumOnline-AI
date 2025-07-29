import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcının tüm profillerini getir
  Future<List<Map<String, dynamic>>> getUserProfiles() async {
    final uid = _auth.currentUser!.uid;
    final userDoc = await _firestore.collection('users').doc(uid).get();

    if (!userDoc.exists) return [];

    final data = userDoc.data() as Map<String, dynamic>;
    final profiles = data['profiles'] as List<dynamic>? ?? [];

    return profiles
        .map((profile) => Map<String, dynamic>.from(profile))
        .toList();
  }

  // Yeni profil ekle
  Future<void> addProfile({
    required String name,
    required int age,
    required int height,
    required double weight,
    required String gender,
    required String bloodType,
    String? chronicIllness,
  }) async {
    final uid = _auth.currentUser!.uid;
    final userDoc = _firestore.collection('users').doc(uid);

    final newProfile = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
      'bloodType': bloodType,
      'chronicIllness': chronicIllness ?? '',
      'isActive': false,
    };

    // Mevcut profilleri al
    final currentData = await userDoc.get();
    final currentProfiles =
        currentData.exists
            ? (currentData.data()?['profiles'] as List<dynamic>? ?? [])
            : [];

    // Eğer bu ilk profil ise, aktif yap
    if (currentProfiles.isEmpty) {
      newProfile['isActive'] = true;
    }

    // Yeni profili ekle
    currentProfiles.add(newProfile);

    // Firestore'da güncelle
    await userDoc.set({'profiles': currentProfiles}, SetOptions(merge: true));

    // Eğer bu profil aktif ise, ana kullanıcı alanlarını da güncelle
    if (newProfile['isActive'] == true) {
      await _updateActiveProfileFields(newProfile);
    }
  }

  // Profil güncelle
  Future<void> updateProfile({
    required String profileId,
    required String name,
    required int age,
    required int height,
    required double weight,
    required String gender,
    required String bloodType,
    String? chronicIllness,
  }) async {
    final uid = _auth.currentUser!.uid;
    final userDoc = _firestore.collection('users').doc(uid);

    final currentData = await userDoc.get();
    if (!currentData.exists) return;

    final currentProfiles =
        currentData.data()?['profiles'] as List<dynamic>? ?? [];

    // Profili bul ve güncelle
    final updatedProfiles =
        currentProfiles.map((profile) {
          final profileMap = Map<String, dynamic>.from(profile);
          if (profileMap['id'] == profileId) {
            return {
              ...profileMap,
              'name': name,
              'age': age,
              'height': height,
              'weight': weight,
              'gender': gender,
              'bloodType': bloodType,
              'chronicIllness': chronicIllness ?? '',
            };
          }
          return profile;
        }).toList();

    // Firestore'da güncelle
    await userDoc.set({'profiles': updatedProfiles}, SetOptions(merge: true));

    // Eğer bu profil aktif ise, ana kullanıcı alanlarını da güncelle
    final updatedProfile = updatedProfiles.firstWhere(
      (profile) => profile['id'] == profileId,
      orElse: () => {},
    );

    if (updatedProfile['isActive'] == true) {
      await _updateActiveProfileFields(updatedProfile);
    }
  }

  // Profil sil
  Future<void> deleteProfile(String profileId) async {
    final uid = _auth.currentUser!.uid;
    final userDoc = _firestore.collection('users').doc(uid);

    final currentData = await userDoc.get();
    if (!currentData.exists) return;

    final currentProfiles =
        currentData.data()?['profiles'] as List<dynamic>? ?? [];

    // Silinecek profilin aktif olup olmadığını kontrol et
    final profileToDelete = currentProfiles.firstWhere(
      (profile) => profile['id'] == profileId,
      orElse: () => {},
    );

    final wasActive = profileToDelete['isActive'] == true;

    // Profili sil
    final updatedProfiles =
        currentProfiles.where((profile) => profile['id'] != profileId).toList();

    // Eğer aktif profil silindiyse ve başka profil varsa, ilkini aktif yap
    if (wasActive && updatedProfiles.isNotEmpty) {
      updatedProfiles[0]['isActive'] = true;
      await _updateActiveProfileFields(updatedProfiles[0]);
    }

    // Firestore'da güncelle
    await userDoc.set({'profiles': updatedProfiles}, SetOptions(merge: true));
  }

  // Aktif profili değiştir
  Future<void> setActiveProfile(String profileId) async {
    final uid = _auth.currentUser!.uid;
    final userDoc = _firestore.collection('users').doc(uid);

    final currentData = await userDoc.get();
    if (!currentData.exists) return;

    final currentProfiles =
        currentData.data()?['profiles'] as List<dynamic>? ?? [];

    // Tüm profilleri pasif yap ve seçilen profili aktif yap
    final updatedProfiles =
        currentProfiles.map((profile) {
          final profileMap = Map<String, dynamic>.from(profile);
          return {...profileMap, 'isActive': profileMap['id'] == profileId};
        }).toList();

    // Firestore'da güncelle
    await userDoc.set({'profiles': updatedProfiles}, SetOptions(merge: true));

    // Aktif profil bilgilerini ana kullanıcı alanlarına kopyala
    final activeProfile = updatedProfiles.firstWhere(
      (profile) => profile['isActive'] == true,
      orElse: () => {},
    );

    if (activeProfile.isNotEmpty) {
      await _updateActiveProfileFields(activeProfile);
    }
  }

  // Aktif profil bilgilerini ana kullanıcı alanlarına kopyala
  Future<void> _updateActiveProfileFields(Map<String, dynamic> profile) async {
    final uid = _auth.currentUser!.uid;
    final userDoc = _firestore.collection('users').doc(uid);

    await userDoc.set({
      'boy': profile['height'].toString(),
      'yas': profile['age'].toString(),
      'kilo': profile['weight'].toString(),
      'cinsiyet': profile['gender'],
      'kan_grubu': profile['bloodType'],
      'kronik_rahatsizlik': profile['chronicIllness'] ?? '',
      'activeProfileId': profile['id'],
    }, SetOptions(merge: true));
  }

  // Aktif profili getir
  Future<Map<String, dynamic>?> getActiveProfile() async {
    final profiles = await getUserProfiles();
    return profiles.firstWhere(
      (profile) => profile['isActive'] == true,
      orElse: () => {},
    );
  }

  // Profil sayısını getir
  Future<int> getProfileCount() async {
    final profiles = await getUserProfiles();
    return profiles.length;
  }

  // Profil ID'sine göre profil getir
  Future<Map<String, dynamic>?> getProfileById(String profileId) async {
    final profiles = await getUserProfiles();
    return profiles.firstWhere(
      (profile) => profile['id'] == profileId,
      orElse: () => {},
    );
  }

  // Aktif kullanıcının adını getir
  Future<String?> getActiveUserName() async {
    final activeProfile = await getActiveProfile();
    if (activeProfile != null && activeProfile.isNotEmpty) {
      // Profil adını döndür, null değilse.
      return activeProfile['name'] as String?;
    }
    // Ad bulunamazsa null döndür.
    return null;
  }
}
