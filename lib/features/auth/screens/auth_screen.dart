import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../dashboard/screens/main_shell.dart';

/// Authentication screen with Login/Signup tabs, Email + Google sign-in
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    if (_tabController.index == 1 && name.isEmpty) {
      _showSnackBar('Please enter your name');
      return;
    }

    try {
      if (_tabController.index == 0) {
        await ref.read(authStateProvider.notifier).loginWithEmail(email, password);
      } else {
        await ref.read(authStateProvider.notifier).signUp(email, password, name);
      }
      if (mounted) _navigateToHome();
    } catch (e) {
      if (mounted) _showSnackBar(_getFirebaseErrorMessage(e.toString()));
    }
  }

  Future<void> _handleGoogleAuth() async {
    try {
      await ref.read(authStateProvider.notifier).loginWithGoogle();
      if (mounted && ref.read(authStateProvider).isLoggedIn) {
        _navigateToHome();
      }
    } catch (e) {
      if (mounted) _showSnackBar(_getFirebaseErrorMessage(e.toString()));
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Please enter your email address first');
      return;
    }
    try {
      await ref.read(authStateProvider.notifier).sendPasswordReset(email);
      if (mounted) {
        _showSnackBar('Password reset email sent! Check your inbox.');
      }
    } catch (e) {
      if (mounted) _showSnackBar(_getFirebaseErrorMessage(e.toString()));
    }
  }

  String _getFirebaseErrorMessage(String error) {
    if (error.contains('user-not-found')) return 'No account found with this email';
    if (error.contains('wrong-password') || error.contains('invalid-credential')) return 'Incorrect password';
    if (error.contains('email-already-in-use')) return 'An account with this email already exists';
    if (error.contains('weak-password')) return 'Password must be at least 6 characters';
    if (error.contains('invalid-email')) return 'Please enter a valid email address';
    if (error.contains('too-many-requests')) return 'Too many attempts. Please try again later';
    if (error.contains('network-request-failed')) return 'No internet connection';
    return 'Something went wrong. Please try again';
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAccent.withValues(alpha: 0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Welcome to MindBloom',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to nurture your positivity journey',
                      style: TextStyle(
                        fontSize: 15,
                        color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Tab bar (Login / Sign Up)
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColors.cardBg : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        onTap: (_) => setState(() {}),
                        indicator: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                        labelStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'Login'),
                          Tab(text: 'Sign Up'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Name field (only for signup)
                    if (_tabController.index == 1) ...[
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Email
                    _buildTextField(
                      controller: _emailController,
                      hint: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      isDarkMode: isDarkMode,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Forgot Password (only login)
                    if (_tabController.index == 0)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: AppColors.secondaryAccent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Primary action button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleEmailAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _tabController.index == 0 ? 'Login' : 'Create Account',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or continue with',
                            style: TextStyle(
                              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Google Sign In
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: authState.isLoading ? null : _handleGoogleAuth,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Google',
                              style: TextStyle(
                                color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Terms
                    Text(
                      'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          if (authState.isLoading)
            LoadingOverlay(
              message: _tabController.index == 0 ? 'Signing you in...' : 'Creating your account...',
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark, 
        fontSize: 15
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark
        ),
        prefixIcon: Icon(
          icon, 
          color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark, 
          size: 20
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
