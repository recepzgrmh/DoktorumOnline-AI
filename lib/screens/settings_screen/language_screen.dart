import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:login_page/widgets/custom_appbar.dart';

// LanguageOption sınıfı ve _languageOptions listesi aynı kalabilir...
class LanguageOption {
  final String nameKey;
  final Locale locale;
  final String flag;

  LanguageOption({
    required this.nameKey,
    required this.locale,
    required this.flag,
  });
}

final List<LanguageOption> _languageOptions = [
  LanguageOption(
    nameKey: 'turkish_language',
    locale: const Locale('tr'),
    flag: '🇹🇷',
  ),
  LanguageOption(
    nameKey: 'english_language',
    locale: const Locale('en'),
    flag: '🇺🇸',
  ),
];

// 1. StatefulWidget'a dönüştürün
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'select_language'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
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
              _languageChanged = true;
            });
            context.setLocale(language.locale);
          }
        },
        splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Text(language.flag, style: const TextStyle(fontSize: 28)),
        title: Text(
          language.nameKey.tr(),
          style: TextStyle(
            fontSize: 17,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color:
                isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
          ),
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
