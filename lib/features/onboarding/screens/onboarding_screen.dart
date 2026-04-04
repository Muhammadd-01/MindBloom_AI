import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../auth/screens/auth_screen.dart';

/// 3-page onboarding flow introducing the app's features
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardingPageData(
      icon: Icons.mic_rounded,
      iconGradient: AppColors.primaryGradient,
      title: 'Share Your Thoughts',
      description:
          'Record your voice or write in your journal. Our AI listens and understands your emotions without judgment.',
      illustration: '🎙️',
    ),
    _OnboardingPageData(
      icon: Icons.insights_rounded,
      iconGradient: AppColors.blueGradient,
      title: 'AI-Powered Insights',
      description:
          'Get real-time sentiment analysis, positivity scores, and personalized suggestions to improve your day.',
      illustration: '📊',
    ),
    _OnboardingPageData(
      icon: Icons.emoji_events_rounded,
      iconGradient: AppColors.amberGradient,
      title: 'Grow Your Positivity',
      description:
          'Track your progress, build streaks, level up, and transform your everyday mindset with AI coaching.',
      illustration: '🏆',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToAuth();
    }
  }

  void _navigateToAuth() {
    ref.read(onboardingProvider.notifier).completeOnboarding();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AuthScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _navigateToAuth,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (_, i) => _OnboardingPage(
                    page: _pages[i],
                    isDarkMode: isDarkMode,
                  ),
                ),
              ),

              // Page indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: _pages.length,
                  effect: WormEffect(
                    dotHeight: 10,
                    dotWidth: 10,
                    spacing: 12,
                    activeDotColor: AppColors.primaryAccent,
                    dotColor: isDarkMode ? AppColors.cardBgLight : AppColors.cardBgLightGray,
                  ),
                ),
              ),

              // Next / Get Started button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_currentPage < _pages.length - 1) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single onboarding page layout
class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData page;
  final bool isDarkMode;

  const _OnboardingPage({
    required this.page,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Big illustration emoji
          Text(
            page.illustration,
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 24),
          // Gradient icon circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: page.iconGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.iconGradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(page.icon, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 40),
          // Title
          Text(
            page.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final LinearGradient iconGradient;
  final String title;
  final String description;
  final String illustration;

  const _OnboardingPageData({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.description,
    required this.illustration,
  });
}
