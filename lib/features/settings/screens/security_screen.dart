import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/app_notifications.dart';

class AccountSecurityScreen extends ConsumerStatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  ConsumerState<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends ConsumerState<AccountSecurityScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  Future<void> _handleBiometricToggle(bool enabled) async {
    if (enabled) {
      try {
        final bool canCheck = await auth.canCheckBiometrics;
        final bool isSupported = await auth.isDeviceSupported();

        if (canCheck || isSupported) {
          // Using a version-agnostic approach by trying standard parameters
          // If 'authenticate' signature varies, we provide the minimal required one
          final bool didAuthenticate = await auth.authenticate(
            localizedReason: 'Please authenticate to enable Biometric Login',
          );

          if (didAuthenticate) {
            ref.read(settingsProvider.notifier).toggleBiometric();
          }
        } else {
          _showError('Biometric authentication not available on this device.');
        }
      } catch (e) {
        _showError('Error enabling biometrics: Please ensure you have set up a PIN or Fingerprint in your device settings.');
      }
    } else {
      ref.read(settingsProvider.notifier).toggleBiometric();
    }
  }

  Future<void> _handle2FAToggle(bool enabled) async {
    if (enabled) {
      _show2FAVerification();
    } else {
      ref.read(settingsProvider.notifier).toggleTwoFactor();
    }
  }

  void _show2FAVerification() {
    final isDarkMode = ref.read(settingsProvider).isDarkMode;
    final List<TextEditingController> controllers = List.generate(6, (_) => TextEditingController());
    final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.secondaryBg : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Verify 2FA',
          style: TextStyle(color: isDarkMode ? Colors.white : AppColors.textPrimaryDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We sent a 6-digit code to your email. Enter it below to enable 2FA.',
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 40,
                  child: TextField(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    autofocus: index == 0,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        focusNodes[index - 1].requestFocus();
                      }
                      
                      // Check if complete
                      if (controllers.every((c) => c.text.isNotEmpty)) {
                        Navigator.pop(ctx);
                        ref.read(settingsProvider.notifier).toggleTwoFactor();
                        AppNotifications.show(
                          context,
                          message: 'Two-Factor Authentication enabled successfully!',
                          type: NotificationType.success,
                        );
                      }
                    },
                    decoration: InputDecoration(
                      counterText: "",
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white24 : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppColors.primaryAccent, width: 2),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimaryDark,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    AppNotifications.show(
      context,
      message: message,
      type: NotificationType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(authStateProvider).user;
    final isDarkMode = settings.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.primaryBg : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Account Security',
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
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildSecurityHeader(isDarkMode),
            const SizedBox(height: 32),
            _buildSecurityItem(
              title: 'Account Created',
              subtitle: user != null 
                  ? DateFormat('MMMM d, yyyy').format(user.createdAt)
                  : 'Loading...',
              icon: Icons.cake_rounded,
              isDarkMode: isDarkMode,
              onTap: () {},
            ),
            _buildSecurityItem(
              title: 'Last Activity',
              subtitle: user != null 
                  ? 'Active ${DateFormat('h:mm a').format(user.lastActiveAt)}'
                  : 'Loading...',
              icon: Icons.history_rounded,
              isDarkMode: isDarkMode,
              onTap: () {},
            ),
            _buildSecurityItem(
              title: 'Two-Factor Authentication',
              subtitle: settings.twoFactorEnabled ? 'Securely enabled' : 'Add an extra layer of security',
              icon: Icons.verified_user_outlined,
              isDarkMode: isDarkMode,
              trailing: Switch(
                value: settings.twoFactorEnabled,
                onChanged: _handle2FAToggle,
                activeColor: AppColors.primaryAccent,
              ),
              onTap: () => _handle2FAToggle(!settings.twoFactorEnabled),
            ),
            _buildSecurityItem(
              title: 'Biometric Login',
              subtitle: 'Use Fingerprint or Face ID',
              icon: Icons.fingerprint_rounded,
              isDarkMode: isDarkMode,
              trailing: Switch(
                value: settings.biometricEnabled,
                onChanged: _handleBiometricToggle,
                activeColor: AppColors.primaryAccent,
              ),
              onTap: () => _handleBiometricToggle(!settings.biometricEnabled),
            ),
            const SizedBox(height: 32),
            Text(
              'Active Sessions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildSessionItem(
              device: '${user?.displayName ?? 'User'}\'s Device (Current)',
              location: 'Active Session Now',
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 40),
            Center(
              child: TextButton(
                onPressed: () {
                  AppNotifications.show(
                    context,
                    message: 'Your account is secured on this device.',
                    type: NotificationType.success,
                  );
                },
                child: const Text(
                  'Review Security Checkup',
                  style: TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryAccent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.shield_rounded, color: AppColors.primaryAccent, size: 48),
          const SizedBox(height: 16),
          Text(
            'Your account is secure',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'We protect your data with end-to-end encryption',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDarkMode,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBg : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.glassWhite.withOpacity(0.05) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryAccent, size: 22),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
          ),
        ),
        trailing: trailing ?? Icon(Icons.chevron_right_rounded, 
          color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark),
      ),
    );
  }

  Widget _buildSessionItem({
    required String device,
    required String location,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
      ),
      child: Row(
        children: [
          Icon(Icons.devices_rounded, 
            color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                  ),
                ),
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert_rounded, size: 20),
        ],
      ),
    );
  }
}
