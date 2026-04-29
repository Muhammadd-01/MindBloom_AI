import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/local_ai_engine.dart';

class BehaviorGameScreen extends ConsumerStatefulWidget {
  const BehaviorGameScreen({super.key});

  @override
  ConsumerState<BehaviorGameScreen> createState() => _BehaviorGameScreenState();
}

class _BehaviorGameScreenState extends ConsumerState<BehaviorGameScreen> {
  Map<String, dynamic>? _aiChallenge;
  bool _isLoading = true;
  bool _hasResponded = false;

  @override
  void initState() {
    super.initState();
    _loadAIChallenge();
  }

  Future<void> _loadAIChallenge() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final challenge = await MindBloomLocalAIEngine.generateAIChallenge();
    
    if (!mounted) return;
    setState(() {
      _aiChallenge = challenge;
      _isLoading = false;
      _hasResponded = false;
    });
  }

  void _handleChoice(int index) {
    if (_hasResponded) return;

    setState(() {
      _hasResponded = true;
    });

    // Grant points for any AI challenge activity
    ref.read(authStateProvider.notifier).addPoints(_aiChallenge?['points'] ?? 50);
  }

  Future<void> _finishChallenge() async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI Mindset Challenge Complete! XP Earned'),
        backgroundColor: AppColors.primaryAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.primaryBg : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Positivity Arena',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
          ),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadAIChallenge,
              color: AppColors.primaryAccent,
            ),
        ],
        leading: IconButton(
          icon: Icon(Icons.close, color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Scenario Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.cardBg : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
                  boxShadow: isDarkMode ? null : [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _aiChallenge?['title'] ?? 'Positivity Quest',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _aiChallenge?['task'] ?? 'Take a deep breath and smile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(),

              const SizedBox(height: 32),
              
              // Points indicator
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars_rounded, color: AppColors.primaryAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Potential Reward: ${_aiChallenge?['points'] ?? 50} XP',
                      style: const TextStyle(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action Buttons
              if (!_hasResponded)
                ElevatedButton(
                  onPressed: () => _handleChoice(1),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primaryAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('I will do this!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                )
              else
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.positive.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.positive.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.positive, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Challenge Accepted!',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.positive),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Complete the task in real life to level up your mindset.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _finishChallenge,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.positive,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: const Text('Finish'),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.5),
            ],
          ),
        ),
      ),
    );
  }
}
