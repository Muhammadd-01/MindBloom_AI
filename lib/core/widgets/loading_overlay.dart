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
        // Outer pulsing ring
        _TweenAnimation(
          duration: const Duration(seconds: 2),
          builder: (context, value) {
            return Container(
              width: 80 + (40 * value),
              height: 80 + (40 * value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 1.0 - value),
                  width: 2,
                ),
              ),
            );
          },
        ),
        // Inner spinning ring
        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(AppColors.primaryAccent),
          ),
        ),
        // Center icon
        const Icon(
          Icons.auto_awesome,
          color: Colors.white,
          size: 24,
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
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
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
