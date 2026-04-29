import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import '../../subscription/screens/subscription_screen.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    await ref.read(authStateProvider.notifier).updateProfile(
      name: _nameController.text,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.primaryAccent,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showImageSourcePicker(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppColors.secondaryBg : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryAccent),
              title: Text('Choose from Gallery', 
                style: TextStyle(color: isDarkMode ? Colors.white : AppColors.textPrimaryDark)),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(authStateProvider.notifier).uploadProfileImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryAccent),
              title: Text('Take a Photo', 
                style: TextStyle(color: isDarkMode ? Colors.white : AppColors.textPrimaryDark)),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(authStateProvider.notifier).uploadProfileImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final isLoading = ref.watch(authStateProvider).isLoading;
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.primaryBg : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Edit Profile',
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
        actions: [
          TextButton(
            onPressed: isLoading ? null : _saveProfile,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.primaryAccent),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        height: double.infinity,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Photo Section
                GestureDetector(
                  onTap: isLoading ? null : () => _showImageSourcePicker(context, isDarkMode),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryAccent, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryAccent.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: user?.photoUrl.isNotEmpty == true
                              ? Image.network(
                                  user!.photoUrl,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Icons.person, size: 60, 
                                    color: isDarkMode ? Colors.white54 : Colors.grey),
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                  },
                                )
                              : Icon(Icons.person, size: 60, 
                                  color: isDarkMode ? Colors.white54 : Colors.grey),
                        ),
                      ),
                      if (isLoading)
                        const Positioned.fill(
                          child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primaryAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Form fields
                _buildTextField(
                  label: 'Display Name',
                  controller: _nameController,
                  icon: Icons.person_outline,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: 'Email',
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  enabled: false,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 40),

                // Account Type Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.cardBg : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark, 
                      width: 1,
                    ),
                    boxShadow: isDarkMode ? null : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Status',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Tier: ${user?.subscriptionTier.label ?? "Seedling"}',
                                  style: TextStyle(
                                    color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (user?.subscriptionTier == SubscriptionTier.forest) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 22),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (user?.subscriptionTier == SubscriptionTier.seedling)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                            );
                          },
                          child: const Text(
                            'Upgrade',
                            style: TextStyle(color: AppColors.highlight),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isDarkMode,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          style: TextStyle(
            color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primaryAccent, size: 20),
            filled: true,
            fillColor: isDarkMode ? AppColors.cardBg : Colors.grey.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
