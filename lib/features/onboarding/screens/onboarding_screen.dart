import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      icon: Icons.auto_awesome_rounded,
      iconGradient: AppColors.primaryGradient,
      title: 'MindBloom AI Coaching',
      description:
          'Your personal AI coach that observes your daily habits and offers gentle nudges toward a more positive, balanced life.',
      illustration: '🌱',
      tagline: 'Nurture Your Growth',
    ),
    _OnboardingPageData(
      icon: Icons.graphic_eq_rounded,
      iconGradient: AppColors.blueGradient,
      title: 'Vocal Behavioral Analysis',
      description:
          'Share your thoughts out loud. Our advanced AI analyzes tone, sentiment, and patterns to give you a deep behavioral mirror.',
      illustration: '📢',
      tagline: 'Speak Your Truth',
    ),
    _OnboardingPageData(
      icon: Icons.workspace_premium_rounded,
      iconGradient: AppColors.amberGradient,
      title: 'Gamified Well-being',
      description:
          'Turn self-awareness into a game. Complete challenges, earn rewards, and watch your positivity score bloom every day.',
      illustration: '🏆',
      tagline: 'Bloom Every Day',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
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
        transitionDuration: const Duration(milliseconds: 800),
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
              // Header with Skip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/images/app_logo.png', width: 32, height: 32)
                        .animate()
                        .fadeIn()
                        .scale(),
                    TextButton(
                      onPressed: _navigateToAuth,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: CustomizableEffect(
                        activeDotDecoration: DotDecoration(
                          width: 24,
                          height: 8,
                          color: AppColors.primaryAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        dotDecoration: DotDecoration(
                          width: 8,
                          height: 8,
                          color: isDarkMode ? Colors.white12 : Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        spacing: 8,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ).copyWith(
                          overlayColor: WidgetStateProperty.all(Colors.white10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1
                                  ? 'Get Started'
                                  : 'Next Step',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == _pages.length - 1
                                  ? Icons.rocket_launch_rounded
                                  : Icons.arrow_forward_ios_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ).animate(target: _currentPage == _pages.length - 1 ? 1 : 0)
                     .shimmer(duration: 1500.ms, delay: 500.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration / Emoji
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Text(
              page.illustration,
              style: const TextStyle(fontSize: 100),
            ),
          ).animate()
           .fadeIn(duration: 600.ms)
           .scale(delay: 200.ms, curve: Curves.elasticOut),
          
          const SizedBox(height: 48),
          
          // Tagline Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: page.iconGradient.colors.first.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              page.tagline.toUpperCase(),
              style: TextStyle(
                color: page.iconGradient.colors.first,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).moveY(begin: 10, end: 0),

          const SizedBox(height: 16),
          
          // Title
          Text(
            page.title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 500.ms).moveY(begin: 10, end: 0),

          const SizedBox(height: 20),
          
          // Description
          Text(
            page.description,
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms).moveY(begin: 10, end: 0),
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
  final String tagline;

  const _OnboardingPageData({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.description,
    required this.illustration,
    required this.tagline,
  });
}
