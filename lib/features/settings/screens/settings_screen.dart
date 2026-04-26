import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/services/guardian_service.dart';
import '../../auth/screens/auth_screen.dart';
import '../widgets/chatbot_sheet.dart';
import 'edit_profile_screen.dart';
import 'security_screen.dart';
import 'language_screen.dart';
import '../../subscription/screens/subscription_screen.dart';
import 'feedback_screen.dart';

/// Settings screen with privacy controls, premium, and profile management
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(authStateProvider).user;
    final isDarkMode = settings.isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: isDarkMode ? AppColors.darkGradient : AppColors.lightGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Profile Card
                    _buildProfileCard(context, user, isDarkMode),

                    const SizedBox(height: 24),

                    // Profile Settings Section
                    _buildSection('Profile Settings', [
                      _settingsAction(
                        'Edit Profile',
                        'Update name and profile photo',
                        Icons.person_outline_rounded,
                        AppColors.primaryAccent,
                        isDarkMode,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                        ),
                      ),
                      _settingsAction(
                        'Account Security',
                        'Password and authentication',
                        Icons.security_rounded,
                        AppColors.secondaryAccent,
                        isDarkMode,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AccountSecurityScreen()),
                        ),
                      ),
                    ], isDarkMode),

                    const SizedBox(height: 20),

                    // AI Coach Card
                    _buildCoachCard(context, isDarkMode),

                    const SizedBox(height: 20),

                    // Premium Card
                    if (user?.subscriptionTier == SubscriptionTier.seedling) _buildPremiumCard(context, ref, isDarkMode),
                    if (user?.subscriptionTier == SubscriptionTier.seedling) const SizedBox(height: 20),

                    // Privacy & Permissions
                    _buildSection('Privacy & Permissions', [
                      _settingsToggle(
                        'Behavior Tracking',
                        'Allow app to analyze your inputs',
                        Icons.track_changes_rounded,
                        settings.trackingEnabled,
                        isDarkMode,
                        () => ref.read(settingsProvider.notifier).toggleTracking(),
                      ),
                      _settingsToggle(
                        'Guardian Mode (Beta)',
                        'Monitor incoming chats for distress',
                        Icons.shield_rounded,
                        settings.guardianModeEnabled,
                        isDarkMode,
                        () async {
                          if (!settings.guardianModeEnabled) {
                            // User wants to turn it on, request permission
                            final granted = await GuardianService.requestPermission();
                            if (granted) {
                              GuardianService.startListening();
                              ref.read(settingsProvider.notifier).toggleGuardianMode();
                              if (context.mounted) _showSnackBar(context, 'Guardian Mode activated');
                            } else {
                              if (context.mounted) _showSnackBar(context, 'Permission denied');
                            }
                          } else {
                            // User wants to turn it off
                            ref.read(settingsProvider.notifier).toggleGuardianMode();
                          }
                        },
                      ),
                    ], isDarkMode),

                    const SizedBox(height: 20),

                    // Nudges & Mindset Alerts
                    _buildSection('Nudges & Mindset Alerts', [
                      _settingsToggle(
                        'Daily Mindset Reminders',
                        'Start your day with positivity',
                        Icons.wb_sunny_outlined,
                        settings.notificationsEnabled,
                        isDarkMode,
                        () => ref.read(settingsProvider.notifier).toggleNotifications(),
                      ),
                      _settingsToggle(
                        'AI Behavioral Insights',
                        'Deep analysis of your thoughts',
                        Icons.insights_outlined,
                        settings.trackingEnabled,
                        isDarkMode,
                        () => ref.read(settingsProvider.notifier).toggleTracking(),
                      ),
                      _settingsToggle(
                        'Islamic Content',
                        'Weekly Quran and Hadith nudges',
                        Icons.auto_stories_rounded,
                        settings.islamicContentEnabled,
                        isDarkMode,
                        () => ref.read(settingsProvider.notifier).toggleIslamicContent(),
                      ),
                    ], isDarkMode),

                    const SizedBox(height: 20),

                    // Display Settings
                    _buildSection('Display', [
                      _settingsToggle(
                        'Dark Mode',
                        isDarkMode ? 'Dark theme active' : 'Light theme active',
                        isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        isDarkMode,
                        isDarkMode,
                        () => ref.read(settingsProvider.notifier).toggleTheme(),
                      ),
                      _settingsAction(
                        'Language',
                        'English',
                        Icons.language_rounded,
                        AppColors.secondaryAccent,
                        isDarkMode,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LanguageScreen()),
                        ),
                      ),
                    ], isDarkMode),

                    const SizedBox(height: 20),

                    // Data Management
                    _buildSection('Data Management', [
                      _settingsAction(
                        'Export My Data',
                        'Download all your data',
                        Icons.download_rounded,
                        AppColors.secondaryAccent,
                        isDarkMode,
                        () => _showSnackBar(context, 'Data export started...'),
                      ),
                      _settingsAction(
                        'Delete All Data',
                        'Permanently remove all your data',
                        Icons.delete_forever_rounded,
                        AppColors.negative,
                        isDarkMode,
                        () => _showDeleteConfirm(context, isDarkMode),
                      ),
                    ], isDarkMode),

                    const SizedBox(height: 20),

                    // About
                    _buildSection('About', [
                      _settingsAction(
                        'Feedback & Reviews',
                        'Rate your experience',
                        Icons.rate_review_rounded,
                        AppColors.primaryAccent,
                        isDarkMode,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                        ),
                      ),
                      _settingsAction(
                        'Privacy Policy',
                        'How we handle your data',
                        Icons.policy_rounded,
                        AppColors.textSecondary,
                        isDarkMode,
                        () {},
                      ),
                      _settingsAction(
                        'Terms of Service',
                        'App usage terms',
                        Icons.description_rounded,
                        AppColors.textSecondary,
                        isDarkMode,
                        () {},
                      ),
                      _settingsAction(
                        'App Version',
                        'v1.0.0 (Build 1)',
                        Icons.info_outline_rounded,
                        AppColors.textSecondary,
                        isDarkMode,
                        () {},
                      ),
                    ], isDarkMode),

                    const SizedBox(height: 20),

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () async {
                          await ref.read(authStateProvider.notifier).logout();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const AuthScreen()),
                              (route) => false,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.negative),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.logout_rounded, color: AppColors.negative, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: AppColors.negative,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
          if (ref.watch(authStateProvider).isLoading)
            const LoadingOverlay(message: 'Logging you out safely...'),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, UserModel? user, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryAccent, width: 2),
              image: user?.photoUrl.isNotEmpty == true
                  ? DecorationImage(
                      image: NetworkImage(user!.photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user?.photoUrl.isEmpty == true
                ? Center(
                    child: Text(
                      user?.displayName.isNotEmpty == true
                          ? user!.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppColors.textPrimaryDark,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user?.displayName ?? 'User',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                      ),
                    ),
                    if (user?.subscriptionTier == SubscriptionTier.forest) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 20),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'user@example.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachCard(BuildContext context, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const ChatbotSheet(),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.secondaryAccent.withValues(alpha: 0.15),
              isDarkMode ? AppColors.glassWhite : Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.secondaryAccent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppColors.blueGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Positivity Coach',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chat with your personal AI coach',
                    style: TextStyle(
                      fontSize: 13, 
                      color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context, WidgetRef ref, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Unlock Forest Tier',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Get unlimited AI reflections, deep behavioral DNA, and custom growth goals.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'View Plans',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.glassWhite : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _settingsToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    bool isDarkMode,
    VoidCallback onToggle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12, 
                    color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (_) => onToggle(),
            activeTrackColor: AppColors.primaryAccent.withValues(alpha: 0.3),
            activeThumbColor: AppColors.primaryAccent,
            inactiveTrackColor: isDarkMode ? AppColors.cardBgLight : AppColors.cardBgLightGray,
          ),
        ],
      ),
    );
  }

  Widget _settingsAction(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isDarkMode,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15, 
                      color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12, 
                      color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showDeleteConfirm(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.secondaryBg : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete All Data?',
          style: TextStyle(color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark),
        ),
        content: Text(
          'This will permanently delete all your data including analyses, reports, and progress. This action cannot be undone.',
          style: TextStyle(color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                _showSnackBar(context, 'Deleting all data...');
                await ref.read(authStateProvider.notifier).deleteAllData();
                await ref.read(authStateProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                    (route) => false,
                    );
                  }
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.negative,
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
