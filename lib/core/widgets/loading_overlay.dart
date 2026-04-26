import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final String message;

  const LoadingOverlay({
    super.key,
    this.message = 'Processing...',
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModernLoader(),
              const SizedBox(height: 24),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernLoader() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer breathing bloom
        _TweenAnimation(
          duration: const Duration(seconds: 3), // Slow, deep breath
          builder: (context, value) {
            final easedValue = Curves.easeInOutSine.transform(value);
            return Container(
              width: 80 + (60 * easedValue),
              height: 80 + (60 * easedValue),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryAccent.withValues(alpha: 0.05 + (0.1 * easedValue)),
              ),
            );
          },
        ),
        // Inner core breathing
        _TweenAnimation(
          duration: const Duration(seconds: 3),
          builder: (context, value) {
            final easedValue = Curves.easeInOutSine.transform(value);
            return Container(
              width: 60 + (20 * easedValue),
              height: 60 + (20 * easedValue),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryAccent.withValues(alpha: 0.2 + (0.3 * easedValue)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAccent.withValues(alpha: 0.3 * easedValue),
                    blurRadius: 20 * easedValue,
                    spreadRadius: 5 * easedValue,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.spa, // Nature/Mindfulness icon (lotus)
                  color: Colors.white.withValues(alpha: 0.8 + (0.2 * easedValue)),
                  size: 30 + (5 * easedValue),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TweenAnimation extends StatefulWidget {
  final Widget Function(BuildContext, double) builder;
  final Duration duration;

  const _TweenAnimation({
    required this.builder,
    required this.duration,
  });

  @override
  State<_TweenAnimation> createState() => _TweenAnimationState();
}

class _TweenAnimationState extends State<_TweenAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Use reverse: true for a breathing inhale/exhale effect
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(context, _controller.value),
    );
  }
}
