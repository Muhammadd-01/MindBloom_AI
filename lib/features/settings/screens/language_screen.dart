import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String _selectedLanguage = 'English';

  final List<Map<String, String>> _languages = [
    {'name': 'English', 'flag': '🇺🇸', 'native': 'English'},
    {'name': 'Arabic', 'flag': '🇸🇦', 'native': 'العربية'},
    {'name': 'Spanish', 'flag': '🇪🇸', 'native': 'Español'},
    {'name': 'French', 'flag': '🇫🇷', 'native': 'Français'},
    {'name': 'German', 'flag': '🇩🇪', 'native': 'Deutsch'},
    {'name': 'Urdu', 'flag': '🇵🇰', 'native': 'اردو'},
    {'name': 'Indonesian', 'flag': '🇮🇩', 'native': 'Bahasa Indonesia'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.primaryBg : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'App Language',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, 
            color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: _languages.length,
          itemBuilder: (context, index) {
            final lang = _languages[index];
            final isSelected = _selectedLanguage == lang['name'];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.primaryAccent.withOpacity(0.1) 
                    : (isDarkMode ? AppColors.cardBg : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? AppColors.primaryAccent 
                      : (isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isDarkMode ? null : [
                  BoxShadow(
                    color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ListTile(
                onTap: () => setState(() => _selectedLanguage = lang['name']!),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                title: Text(
                  lang['name']!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                  ),
                ),
                subtitle: Text(
                  lang['native']!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryAccent, size: 28)
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}
