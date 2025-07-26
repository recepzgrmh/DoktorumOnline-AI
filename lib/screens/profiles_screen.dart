import 'package:flutter/material.dart';
import 'package:login_page/services/tutorial_service.dart';
import 'package:login_page/widgets/coachmark_desc.dart';
import 'package:login_page/widgets/custom_button.dart';
import 'package:login_page/widgets/profile_form.dart';
import 'package:login_page/widgets/empty_state_widget.dart';
import 'package:login_page/widgets/loading_widget.dart';
import 'package:login_page/services/profile_service.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class ProfilesScreen extends StatefulWidget {
  final GlobalKey? helpButtonKey;
  const ProfilesScreen({super.key, this.helpButtonKey});

  @override
  ProfilesScreenState createState() => ProfilesScreenState();
}

class ProfilesScreenState extends State<ProfilesScreen> {
  // --- EĞİTİM İÇİN EKLENEN KOD BAŞLANGICI ---
  TutorialCoachMark? tutorialCoachMark;
  final List<TargetFocus> targets = [];
  final GlobalKey _newUser = GlobalKey();
  final GlobalKey _firstProfileCard = GlobalKey();
  // --- EĞİTİM İÇİN EKLENEN KOD SONU ---

  final _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _boyController = TextEditingController();
  final _yasController = TextEditingController();
  final _kiloController = TextEditingController();

  String? _cinsiyet;
  String? _kanGrubu;
  bool _isFormLoading = false;
  bool _isEditing = false;
  String? _editingProfileId;

  bool _isLoading = true;
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfiles();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _boyController.dispose();
    _yasController.dispose();
    _kiloController.dispose();
    tutorialCoachMark?.finish(); // Eğitimi temizle
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await _profileService.getUserProfiles();
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profil yükleme hatası: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  // --- EĞİTİM İÇİN EKLENEN KOD BAŞLANGICI ---
  void showTutorial() {
    _initTargets();
    if (targets.isEmpty || !mounted) return;
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      onFinish: () => TutorialService.markTutorialAsSeen('profiles'),
      onSkip: () {
        TutorialService.markTutorialAsSeen('profiles');
        return true;
      },
    )..show(context: context, rootOverlay: true);
  }

  void _initTargets() {
    targets.clear();

    // 1. Hedef: Yardım Butonu
    if (widget.helpButtonKey?.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "Help Button",
          keyTarget: widget.helpButtonKey,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder:
                  (context, controller) => CoachmarkDesc(
                    text:
                        'Uygulama yönergelerini tekrar görmek için bu butona basabilirsin',
                    next: 'İleri',
                    skip: 'Geç',
                    onNext: controller.next,
                    onSkip: controller.skip,
                  ),
            ),
          ],
        ),
      );
    }

    // 2. Hedef: İlk Profil Kartı
    if (_profiles.isNotEmpty && _firstProfileCard.currentContext != null) {
      targets.add(
        TargetFocus(
          shape: ShapeLightFocus.RRect,
          identify: "Profile Card Key",
          keyTarget: _firstProfileCard,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder:
                  (context, controller) => CoachmarkDesc(
                    text:
                        'Profil kartına tıklayarak düzenleyebilir veya aktif yapabilirsin',
                    next: 'İleri',
                    skip: 'Geç',
                    onNext: controller.next,
                    onSkip: controller.skip,
                  ),
            ),
          ],
        ),
      );
    }

    // 3. Hedef: Yeni Profil Ekle Butonu
    if (_newUser.currentContext != null) {
      targets.add(
        TargetFocus(
          identify: "Button Key",
          keyTarget: _newUser,
          shape: ShapeLightFocus.RRect,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder:
                  (context, controller) => CoachmarkDesc(
                    text: 'Buradan yeni profil ekleyebilirsin',
                    next: 'Bitir',
                    skip: 'Geç',
                    onNext: controller.skip,
                    onSkip: controller.skip,
                  ),
            ),
          ],
        ),
      );
    }
  }
  // --- EĞİTİM İÇİN EKLENEN KOD SONU ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:
          _isLoading
              ? const LoadingWidget(message: "Profiller yükleniyor...")
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sağlık Profilleriniz',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sağlık bilgilerinizi yönetin ve AI doktorunuzun size daha iyi hizmet vermesini sağlayın.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF757575),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Expanded(
                        child:
                            _profiles.isEmpty
                                ? const EmptyStateWidget(
                                  message:
                                      'Henüz profil eklenmemiş\nİlk profilinizi ekleyerek başlayın',
                                  icon: Icons.person_add,
                                )
                                : ListView.builder(
                                  itemCount: _profiles.length,
                                  itemBuilder: (context, index) {
                                    final profile = _profiles[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16.0,
                                      ),
                                      // Sadece ilk karta key ata
                                      child: _buildProfileCard(
                                        profile,
                                        index == 0 ? _firstProfileCard : null,
                                      ),
                                    );
                                  },
                                ),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        key: _newUser, // Eğitim için key
                        label: 'Yeni Profil Ekle',
                        onPressed: () => _showProfileForm(),
                        icon: const Icon(Icons.add),
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        isFullWidth: true,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  // Profil kartını oluşturan widget
  Widget _buildProfileCard(Map<String, dynamic> profile, Key? cardKey) {
    final bool isActive = profile['isActive'] ?? false;
    final String profileId = profile['id'] as String;

    return Card(
      key: cardKey,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _setActiveProfile(profileId),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF2196F3) : Colors.grey[300],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.person,
                  color: isActive ? Colors.white : Colors.grey[600],
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => _showProfileForm(profile: profile),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          profile['name'] ?? 'Profil',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF424242),
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Aktif',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${profile['age']} yaş, ${profile['height']} cm, ${profile['weight']} kg',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${profile['gender']} • ${profile['bloodType']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF757575)),
              onSelected: (value) {
                if (value == 'edit') _showProfileForm(profile: profile);
                if (value == 'activate' && !isActive) {
                  _setActiveProfile(profileId);
                }
                if (value == 'delete') {
                  _showDeleteConfirmation(
                    profileId,
                    profile['name'] ?? 'Profil',
                  );
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Düzenle'),
                        ],
                      ),
                    ),
                    if (!isActive)
                      const PopupMenuItem(
                        value: 'activate',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 20),
                            SizedBox(width: 8),
                            Text('Aktif Yap'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Sil', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  // Profil ekleme/düzenleme formunu gösteren metot
  void _showProfileForm({Map<String, dynamic>? profile}) {
    _isEditing = profile != null;
    _editingProfileId = profile?['id'];

    if (profile != null) {
      _nameController.text = profile['name'] ?? '';
      _boyController.text = profile['height']?.toString() ?? '';
      _yasController.text = profile['age']?.toString() ?? '';
      _kiloController.text = profile['weight']?.toString() ?? '';
      _cinsiyet = profile['gender'];
      _kanGrubu = profile['bloodType'];
    } else {
      _nameController.clear();
      _boyController.clear();
      _yasController.clear();
      _kiloController.clear();
      _cinsiyet = null;
      _kanGrubu = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder: (BuildContext context, StateSetter setModalState) {
              return _buildProfileForm(setModalState);
            },
          ),
    );
  }

  // Formun kendisini oluşturan widget
  Widget _buildProfileForm(StateSetter setModalState) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        minimum: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Profili Düzenle' : 'Yeni Profil Ekle',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFF757575)),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 500),
                    child: ProfileForm(
                      nameController: _nameController,
                      boyController: _boyController,
                      yasController: _yasController,
                      kiloController: _kiloController,
                      cinsiyet: _cinsiyet,
                      kanGrubu: _kanGrubu,
                      onCinsiyetChanged:
                          (value) => setModalState(() => _cinsiyet = value),
                      onKanGrubuChanged:
                          (value) => setModalState(() => _kanGrubu = value),
                    ),
                  ),
                ),
                CustomButton(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  label: _isEditing ? 'Profili Güncelle' : 'Profili Kaydet',
                  onPressed: () => _saveProfile(context),
                  isLoading: _isFormLoading,
                  isFullWidth: true,
                ),
                SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Profil kaydetme/güncelleme mantığı
  Future<void> _saveProfile(BuildContext modalContext) async {
    if (!_formKey.currentState!.validate()) return;

    // Formun kendi state'i için setState kullanmak yerine StateSetter'ı kullanmak daha doğru olurdu,
    // ancak mevcut yapıda bu da çalışır.
    setState(() => _isFormLoading = true);

    try {
      if (_isEditing && _editingProfileId != null) {
        await _profileService.updateProfile(
          profileId: _editingProfileId!,
          name: _nameController.text,
          age: int.parse(_yasController.text),
          height: int.parse(_boyController.text),
          weight: double.parse(_kiloController.text),
          gender: _cinsiyet!,
          bloodType: _kanGrubu!,
        );
      } else {
        await _profileService.addProfile(
          name: _nameController.text,
          age: int.parse(_yasController.text),
          height: int.parse(_boyController.text),
          weight: double.parse(_kiloController.text),
          gender: _cinsiyet!,
          bloodType: _kanGrubu!,
        );
      }

      if (!mounted) return;
      Navigator.pop(modalContext); // Formu kapat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Profil güncellendi' : 'Profil kaydedildi',
          ),
          backgroundColor: Colors.green,
        ),
      );
      setState(
        () => _isLoading = true,
      ); // Yeniden yükleme için loading state'i aktif et
      _loadProfiles(); // Listeyi yenile
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(modalContext);
      ScaffoldMessenger.of(context).showSnackBar(
        // Hatayı kullanıcıya özel bir şekilde düzenledim
        SnackBar(
          content: Text(
            'Hata Lütfen Geçerli Değerler Girerek Tekrar deneyiniz',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Formun state'ini güncelleyen setState
      if (mounted) {
        setState(() => _isFormLoading = false);
      }
    }
  }

  // Aktif profili ayarlama mantığı
  Future<void> _setActiveProfile(String profileId) async {
    setState(() => _isLoading = true);
    try {
      await _profileService.setActiveProfile(profileId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktif profil değiştirildi'),
          backgroundColor: Colors.green,
        ),
      );
      _loadProfiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  // Profil silme onayı gösterme
  void _showDeleteConfirmation(String profileId, String profileName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Profili Sil'),
            content: Text(
              '$profileName profilini silmek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteProfile(profileId);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Sil'),
              ),
            ],
          ),
    );
  }

  // Profil silme mantığı
  Future<void> _deleteProfile(String profileId) async {
    setState(() => _isLoading = true);
    try {
      await _profileService.deleteProfile(profileId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil silindi'),
          backgroundColor: Colors.green,
        ),
      );
      _loadProfiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }
}
