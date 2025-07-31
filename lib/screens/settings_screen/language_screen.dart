import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:login_page/screens/main_navigation_screen.dart';
import 'package:login_page/widgets/custom_appbar.dart';
import 'package:login_page/widgets/custom_page_route.dart';

// LanguageOption sınıfı ve _languageOptions listesi aynı kalabilir...
class LanguageOption {
  final String localName;
  final String nameKey;
  final Locale locale;

  LanguageOption({
    required this.localName,
    required this.nameKey,
    required this.locale,
  });
}

final List<LanguageOption> _languageOptions = [
  LanguageOption(
    localName: 'العربية',
    nameKey: 'arabic_language',
    locale: const Locale('ar'),
  ),
  LanguageOption(
    localName: 'Deutsch',
    nameKey: 'german_language',
    locale: const Locale('de'),
  ),
  LanguageOption(
    localName: 'Ελληνικά',
    nameKey: 'greek_language',
    locale: const Locale('el'),
  ),
  LanguageOption(
    localName: 'English',
    nameKey: 'english_language',
    locale: const Locale('en'),
  ),
  LanguageOption(
    localName: 'Español',
    nameKey: 'spanish_language',
    locale: const Locale('es'),
  ),
  LanguageOption(
    localName: 'Français',
    nameKey: 'french_language',
    locale: const Locale('fr', 'FR'),
  ),
  LanguageOption(
    localName: 'हिंदी',
    nameKey: 'hindi_language',
    locale: const Locale('hi'),
  ),
  LanguageOption(
    localName: 'Italiano',
    nameKey: 'italian_language',
    locale: const Locale('it'),
  ),
  LanguageOption(
    localName: '日本語',
    nameKey: 'japanese_language',
    locale: const Locale('ja'),
  ),
  LanguageOption(
    localName: '한국어',
    nameKey: 'korean_language',
    locale: const Locale('ko'),
  ),
  LanguageOption(
    localName: 'Português',
    nameKey: 'portuguese_language',
    locale: const Locale('pt', 'PT'),
  ),
  LanguageOption(
    localName: 'русский',
    nameKey: 'russian_language',
    locale: const Locale('ru'),
  ),
  LanguageOption(
    localName: 'Türkçe',
    nameKey: 'turkish_language',
    locale: const Locale('tr'),
  ),
  LanguageOption(
    localName: '简体中文',
    nameKey: 'chinese_language',
    locale: const Locale('zh', 'CN'),
  ),
];

// 1. StatefulWidget'a dönüştürün
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  bool _loading = false;
  // 2. Dilin değişip değişmediğini takip edecek bir state ekleyin
  bool _languageChanged = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(
        actions: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.blue,
            ),
            // 3. Geri giderken değişikliğin durumunu gönderin
            onPressed: () => Navigator.pop(context, _languageChanged),
          ),
        ],
        title: 'language_and_region'.tr(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Column(
                  children:
                      _languageOptions.map((language) {
                        return _buildLanguageTile(context, language);
                      }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, LanguageOption language) {
    final bool isSelected = context.locale == language.locale;

    return Card(
      elevation: isSelected ? 2 : 0.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isSelected
                ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                )
                : BorderSide.none,
      ),
      child: ListTile(
        onTap: () {
          if (!isSelected) {
            // 4. Dil değiştiğinde state'i güncelleyin
            setState(() {
              Navigator.of(
                context,
              ).pushReplacement(CustomPageRoute(child: MainScreen()));
              _languageChanged = true;
            });
            context.setLocale(language.locale);
          }
        },
        splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              language.localName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              language.nameKey.tr(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color:
                    isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        trailing:
            isSelected
                ? Icon(
                  Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                )
                : Icon(
                  Icons.check_circle_outline_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
      ),
    );
  }
}
