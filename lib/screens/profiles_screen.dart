import 'package:flutter/material.dart';
import 'package:login_page/widgets/coachmark_desc.dart';
import 'package:login_page/widgets/custom_button.dart';
import 'package:login_page/widgets/my_drawer.dart';
import 'package:login_page/widgets/profile_form.dart';
import 'package:login_page/widgets/empty_state_widget.dart';
import 'package:login_page/widgets/loading_widget.dart';
import 'package:login_page/services/profile_service.dart';
import 'package:login_page/services/tutorial_service.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  TutorialCoachMark? tutorialCoachMark;
  List<TargetFocus> targets = [];

  final GlobalKey _menuDrawer = GlobalKey();
  final GlobalKey _newUser = GlobalKey();
  GlobalKey keyButton2 = GlobalKey();
  GlobalKey keyButton3 = GlobalKey();

  final _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();

  // ProfileForm için controller'lar
  final _nameController = TextEditingController();
  final _boyController = TextEditingController();
  final _yasController = TextEditingController();
  final _kiloController = TextEditingController();

  String? _cinsiyet;
  String? _kanGrubu;
  bool _isLoading = false;
  bool _isEditing = false;
  String? _editingProfileId;
  List<Map<String, dynamic>> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _checkAndShowTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenTutorial = prefs.getBool('hasSeenProfilesTutorial') ?? false;

      if (!hasSeenTutorial) {
        _showTutorialCoachmar();
        // Tutorial'ı gördüğünü kaydet
        await prefs.setBool('hasSeenProfilesTutorial', true);
      }
    } catch (e) {
      // SharedPreferences hatası durumunda tutorial'ı göster
      _showTutorialCoachmar();
    }
  }

  void _showTutorialCoachmar() {
    _iniTarget();
    tutorialCoachMark = TutorialCoachMark(targets: targets)
      ..show(context: context, rootOverlay: true);
  }

  void _iniTarget() {
    targets = [
      TargetFocus(
        identify: "Drawer Key",
        keyTarget: _menuDrawer,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return CoachmarkDesc(
                text: 'Menüye buradan ulaşabilirsin',
                next: 'İleri',
                skip: 'Geç',
                onNext: controller.next,
                onSkip: controller.skip,
              );
            },
          ),
        ],
      ),

      TargetFocus(
        identify: "Help Button",
        keyTarget: keyButton3,

        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return CoachmarkDesc(
                text:
                    'Uygulama Yönergelerine tekrar bakmak için bu butona basabilirsin',
                next: 'İleri',
                skip: 'Geç',
                onNext: controller.next,
                onSkip: controller.skip,
              );
            },
          ),
        ],
      ),
    ];

    // Eğer profil varsa profil kartı tutorial'ını ekle
    if (_profiles.isNotEmpty) {
      targets.add(
        TargetFocus(
          shape: ShapeLightFocus.RRect,
          identify: "Profile Card Key",
          keyTarget: keyButton2,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) {
                return CoachmarkDesc(
                  text:
                      'Profil kartına tıklayarak düzenleyebilir veya aktif yapabilirsin',
                  next: 'İleri',
                  skip: 'Geç',
                  onNext: controller.next,
                  onSkip: controller.skip,
                );
              },
            ),
          ],
        ),
      );
    }

    targets.add(
      TargetFocus(
        identify: "Button Key",
        keyTarget: _newUser,
        shape: ShapeLightFocus.RRect,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return CoachmarkDesc(
                text: 'Buradan yeni profil ekleyebilirsin',
                next: 'İleri',
                skip: 'Geç',
                onNext: controller.next,
                onSkip: controller.skip,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _boyController.dispose();
    _yasController.dispose();
    _kiloController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await _profileService.getUserProfiles();
      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });

      // Profiller yüklendikten sonra tutorial'ı kontrol et
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAndShowTutorial();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profil yükleme hatası: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

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
      builder: (context) => _buildProfileForm(),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
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
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: ProfileForm(
                    nameController: _nameController,
                    boyController: _boyController,
                    yasController: _yasController,
                    kiloController: _kiloController,
                    cinsiyet: _cinsiyet,
                    kanGrubu: _kanGrubu,
                    onCinsiyetChanged: (value) {
                      setState(() => _cinsiyet = value);
                    },
                    onKanGrubuChanged: (value) {
                      setState(() => _kanGrubu = value);
                    },
                  ),
                ),
              ),

              CustomButton(
                label: _isEditing ? 'Profili Güncelle' : 'Profili Kaydet',
                onPressed: _saveProfile,
                isLoading: _isLoading,
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                isFullWidth: true,
                verticalPadding: 16.0,
                horizontalPadding: 24.0,
                minHeight: 48.0,
                elevation: 2.0,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditing && _editingProfileId != null) {
        // Profil güncelle
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
        // Yeni profil ekle
        await _profileService.addProfile(
          name: _nameController.text,
          age: int.parse(_yasController.text),
          height: int.parse(_boyController.text),
          weight: double.parse(_kiloController.text),
          gender: _cinsiyet!,
          bloodType: _kanGrubu!,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Profil güncellendi' : 'Profil kaydedildi',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadProfiles(); // Profilleri yeniden yükle
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Aktif profili değiştir
  Future<void> _setActiveProfile(String profileId) async {
    try {
      await _profileService.setActiveProfile(profileId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktif profil değiştirildi'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProfiles(); // Profilleri yeniden yükle
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Profil silme onayı göster
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

  // Profili sil
  Future<void> _deleteProfile(String profileId) async {
    try {
      await _profileService.deleteProfile(profileId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil silindi'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProfiles(); // Profilleri yeniden yükle
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: MyDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2196F3),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profiller',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Color(0xFF2196F3),
          ),
        ),
        leading: Builder(
          builder:
              (context) => IconButton(
                key: _menuDrawer,
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
        actions: [
          IconButton(
            key: keyButton3,
            icon: const Icon(Icons.help_outline),
            onPressed: () async {
              // Tüm tutorial'ları sıfırla
              await TutorialService.resetAllTutorials();

              // Mevcut sayfanın tutorial'ını göster
              _showTutorialCoachmar();
            },
            tooltip: 'Tüm Tutorial\'ları Sıfırla',
          ),
        ],
      ),
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

                      // Profil kartları
                      Expanded(
                        child:
                            _profiles.isEmpty
                                ? EmptyStateWidget(
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
                                      child: _buildProfileCard(profile, index),
                                    );
                                  },
                                ),
                      ),

                      const SizedBox(height: 16),
                      CustomButton(
                        key: _newUser,
                        label: 'Yeni Profil Ekle',
                        onPressed: () => _showProfileForm(),
                        icon: const Icon(Icons.add),
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        isFullWidth: true,
                        verticalPadding: 16.0,
                        horizontalPadding: 24.0,
                        minHeight: 48.0,
                        elevation: 2.0,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> profile, int index) {
    final isActive = profile['isActive'] as bool;
    final profileId = profile['id'] as String;

    // İlk profil kartı için GlobalKey kullan
    final GlobalKey cardKey = index == 0 ? keyButton2 : GlobalKey();

    return Card(
      key: cardKey,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Profil avatarı
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

            // Profil bilgileri
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
                                fontWeight: FontWeight.w500,
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

            // Aksiyon butonları
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF757575)),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showProfileForm(profile: profile);
                    break;
                  case 'activate':
                    if (!isActive) {
                      _setActiveProfile(profileId);
                    }
                    break;
                  case 'delete':
                    _showDeleteConfirmation(
                      profileId,
                      profile['name'] ?? 'Profil',
                    );
                    break;
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
}
