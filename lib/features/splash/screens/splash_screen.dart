import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Splash screen with animated logo and tagline
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    // Logo animation — elastic bounce-in
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.5)),
    );

    // Text slide-up + fade
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(_textController);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    // Mindfulness "Breathing" pulse behind logo (4 seconds inhale, 4 seconds exhale)
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.85, end: 1.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _textController.forward();
    });

    // Signal that splash is finished after minimum animation time
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        ref.read(splashFinishedProvider.notifier).state = true;
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Multi-layered mindfulness ripples
                AnimatedBuilder(
                  animation: _pulseScale,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer subtle ripple
                        Container(
                          width: 200 * _pulseScale.value,
                          height: 200 * _pulseScale.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryAccent.withOpacity(0.05),
                          ),
                        ),
                        // Inner prominent ripple
                        Container(
                          width: 150 * _pulseScale.value,
                          height: 150 * _pulseScale.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryAccent.withOpacity(0.1),
                          ),
                        ),
                        if (child != null) child,
                      ],
                    );
                  },
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryAccent.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Left half of the original image (Brain side)
                              ClipRect(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: 0.5,
                                  child: Image.asset(
                                    'assets/images/app_logo.png',
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                              .animate(delay: 600.ms)
                              .scale(duration: 800.ms, curve: Curves.elasticOut)
                              .slideX(begin: 0.5, end: 0, duration: 600.ms, curve: Curves.easeOutCubic)
                              .fadeIn(duration: 400.ms),
                              
                              // Right half of the original image (Plant side)
                              ClipRect(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  widthFactor: 0.5,
                                  child: Image.asset(
                                    'assets/images/app_logo.png',
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                              .animate(delay: 300.ms)
                              .scale(duration: 800.ms, curve: Curves.elasticOut)
                              .slideX(begin: -0.5, end: 0, duration: 600.ms, curve: Curves.easeOutCubic)
                              .fadeIn(duration: 400.ms),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
  
                const SizedBox(height: 40),
  
                // App name and tagline
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        const Text(
                          'MindBloom',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              AppColors.primaryGradient.createShader(bounds),
                          child: const Text('MindBloom', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nurture your mind,\ngrow your positivity',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
  
                const SizedBox(height: 60),
  
                // Loading spinner
                FadeTransition(
                  opacity: _textOpacity,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.primaryAccent.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
