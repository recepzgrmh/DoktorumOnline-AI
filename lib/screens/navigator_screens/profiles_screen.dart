import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:login_page/services/firebase_analytics.dart';
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
  TutorialCoachMark? tutorialCoachMark;
  final List<TargetFocus> targets = [];
  final GlobalKey _newUser = GlobalKey();
  final GlobalKey _firstProfileCard = GlobalKey();

  final _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _boyController = TextEditingController();
  final _yasController = TextEditingController();
  final _kiloController = TextEditingController();

  String? _cinsiyet;
  String? _kanGrubu;
  String? _sigara;
  String? _alkol;
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
    tutorialCoachMark?.finish();
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
        ).showSnackBar(SnackBar(content: Text('profile_load_error: $e').tr()));
        setState(() => _isLoading = false);
      }
    }
  }

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
                    text: 'tutorial_help_button'.tr(),
                    next: 'next'.tr(),
                    skip: 'skip'.tr(),
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
                    text: 'tutorial_profile_card'.tr(),
                    next: 'next'.tr(),
                    skip: 'skip'.tr(),
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
                    text: 'tutorial_add_profile'.tr(),
                    next: 'finish'.tr(),
                    skip: 'skip'.tr(),
                    onNext: controller.skip,
                    onSkip: controller.skip,
                  ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:
          _isLoading
              ? const LoadingWidget(message: "loading_profiles")
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'health_profiles_title',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ).tr(),
                      const SizedBox(height: 8),
                      const Text(
                        'health_profiles_subtitle',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF757575),
                        ),
                      ).tr(),
                      const SizedBox(height: 32),
                      Expanded(
                        child:
                            _profiles.isEmpty
                                ? EmptyStateWidget(
                                  message: 'empty_state_message'.tr(),
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
                        key: _newUser,
                        label: 'add_new_profile'.tr(),
                        onPressed: () {
                          AnalyticsService.instance.logButtonClick(
                            buttonName: 'add_new_profile_button',
                            screenName: 'profile_screen',
                          );
                          _showProfileForm();
                        },
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
                          profile['name'] ?? 'profile'.tr(),
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
                            child:
                                const Text(
                                  'active',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ).tr(),
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
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20),
                          const SizedBox(width: 8),
                          const Text('edit').tr(),
                        ],
                      ),
                    ),
                    if (!isActive)
                      PopupMenuItem(
                        value: 'activate',
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, size: 20),
                            const SizedBox(width: 8),
                            const Text('make_active').tr(),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'delete',
                            style: TextStyle(color: Colors.red),
                          ).tr(),
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
      _sigara = profile['smokeType'];
      _alkol = profile['alcoholType'];
    } else {
      _nameController.clear();
      _boyController.clear();
      _yasController.clear();
      _kiloController.clear();
      _cinsiyet = null;
      _kanGrubu = null;
      _sigara = null;
      _alkol = null;
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
                      _isEditing ? 'edit_profile'.tr() : 'update_profile'.tr(),
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
                      sigara: _sigara,
                      alkol: _alkol,
                      onCinsiyetChanged:
                          (value) => setModalState(() => _cinsiyet = value),
                      onKanGrubuChanged:
                          (value) => setModalState(() => _kanGrubu = value),
                      onSigaraChanged:
                          (value) => setModalState(() => _sigara = value),
                      onAlkolChanged:
                          (value) => setModalState(() => _alkol = value),
                    ),
                  ),
                ),
                CustomButton(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  label:
                      _isEditing ? 'update_profile'.tr() : 'save_profile'.tr(),
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
          smokeType: _sigara!,
          alcoholType: _alkol!,
        );
      } else {
        await _profileService.addProfile(
          name: _nameController.text,
          age: int.parse(_yasController.text),
          height: int.parse(_boyController.text),
          weight: double.parse(_kiloController.text),
          gender: _cinsiyet!,
          bloodType: _kanGrubu!,
          smokeType: _sigara!,
          alcoholType: _alkol!,
        );
      }

      if (!mounted) return;
      Navigator.pop(modalContext); // Formu kapat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'profile_update_success'.tr()
                : 'profile_saved_success'.tr(),
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
        SnackBar(
          content: Text('generic_error_message').tr(),
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
        SnackBar(
          content: Text('active_profile_changed').tr(),
          backgroundColor: Colors.green,
        ),
      );
      _loadProfiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_prefix: $e').tr(),
          backgroundColor: Colors.red,
        ),
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
            title: const Text('delete_profile').tr(),
            content: Text('delete_confirmation'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel').tr(),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteProfile(profileId);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('delete').tr(),
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
        SnackBar(
          content: Text('profile_deleted_success').tr(),
          backgroundColor: Colors.green,
        ),
      );
      _loadProfiles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_prefix: $e').tr(),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }
}
