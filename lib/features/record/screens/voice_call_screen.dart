import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/local_ai_engine.dart';
import '../../../core/utils/app_notifications.dart';
import '../../../core/models/models.dart';
import '../../subscription/screens/subscription_screen.dart';


class VoiceCallScreen extends ConsumerStatefulWidget {
  const VoiceCallScreen({super.key});

  @override
  ConsumerState<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends ConsumerState<VoiceCallScreen> with TickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _wordsSpoken = "";
  String _coachResponse = "";
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) {
        print('STT Error: $error');
        if (mounted) {
          AppNotifications.showError(context, "Microphone access is required for neural calls.");
        }
      },
      onStatus: (status) {
        if (status == 'done' && _isListening) {
          _handleUserDoneSpeaking();
        }
      },
    );
    
    // Auto-start check after init
    if (mounted) {
      setState(() {});
      _checkLimitAndStart();
    }
  }

  void _checkLimitAndStart() {
    final dashboard = ref.read(dashboardProvider);
    final user = ref.read(authStateProvider).user;
    final currentEntries = dashboard.todayReport?.entriesCount ?? 0;
    final limit = user?.subscriptionTier.dailyLimit ?? SubscriptionTier.seedling.dailyLimit;

    if (currentEntries >= limit) {
      _showLimitDialog();
    }
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Growth Limit Reached", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Your seedling plan allows 3 neural calls per day. Upgrade to Bloom for unlimited growth.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close voice screen
            },
            child: const Text("Maybe Later", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Upgrade Now"),
          ),
        ],
      ),
    );
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    
    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() => _isSpeaking = false);
        _startListening(); // Resume listening after AI finishes speaking
      }
    });
  }

  @override
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) return;
    
    // Re-check limit before each session
    final dashboard = ref.read(dashboardProvider);
    final user = ref.read(authStateProvider).user;
    final currentEntries = dashboard.todayReport?.entriesCount ?? 0;
    final limit = user?.subscriptionTier.dailyLimit ?? SubscriptionTier.seedling.dailyLimit;

    if (currentEntries >= limit) {
      _showLimitDialog();
      return;
    }

    setState(() {
      _isListening = true;
      _isProcessing = false;
      _wordsSpoken = "";
    });

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _wordsSpoken = result.recognizedWords;
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  Future<void> _handleUserDoneSpeaking() async {
    if (_wordsSpoken.isEmpty) return;
    
    await _speechToText.stop();
    setState(() {
      _isListening = false;
      _isProcessing = true;
    });

    // Get context from assessments
    final assessmentHistory = ref.read(assessmentProvider).history;
    String? psychContext;
    if (assessmentHistory.isNotEmpty) {
      final latest = assessmentHistory.first;
      psychContext = "User's latest ${latest.type.toUpperCase()} level is ${latest.resultLevel}.";
    }

    try {
      final response = await MindBloomLocalAIEngine.chatWithCoach(
        _wordsSpoken, 
        psychologicalContext: psychContext
      );
      
      if (mounted) {
        setState(() {
          _coachResponse = response;
          _isProcessing = false;
        });
        
        // Save to history as a "voice" entry to count towards limit
        final user = ref.read(authStateProvider).user;
        if (user != null) {
          await ref.read(analysisProvider.notifier).analyze(
            text: _wordsSpoken, 
            userId: user.uid, 
            inputType: 'voice'
          );
        }

        await _flutterTts.speak(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        AppNotifications.showError(context, "Our neural link is a bit unstable. Let's try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryAccent.withOpacity(0.1),
              Colors.black,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'LIVE CALL',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Neural Visualizer
              _buildNeuralVisualizer(),
              
              const SizedBox(height: 60),
              
              // Status & Text
              _buildStatusIndicator(),
              
              const SizedBox(height: 24),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    if (_isListening)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primaryAccent.withOpacity(0.2)),
                        ),
                        child: Text(
                          _wordsSpoken.isEmpty ? "Speak now, I'm listening..." : _wordsSpoken,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ).animate().fadeIn().scale(),
                    if (!_isListening && _isSpeaking)
                      Text(
                        _coachResponse,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ).animate().fadeIn(),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Controls
              _buildControls(),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeuralVisualizer() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryAccent.withOpacity(0.05),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAccent.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          
          // Core Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryAccent.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              _isSpeaking ? Icons.auto_awesome_rounded : Icons.psychology_rounded,
              color: Colors.white,
              size: 50,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .shimmer(duration: 2.seconds, color: Colors.white24),
           
          // Orbital Rings
          ...List.generate(3, (index) {
            return RotationTransition(
              turns: AlwaysStoppedAnimation(index / 3),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white10,
                    width: 1,
                  ),
                ),
              ),
            );
          }).animate(onPlay: (c) => c.repeat())
            .rotate(duration: 10.seconds),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    String text = "Connecting...";
    Color color = Colors.white54;
    
    if (_isListening) {
      text = "COACH IS LISTENING";
      color = AppColors.primaryAccent;
    } else if (_isProcessing) {
      text = "NEURAL ENGINE PROCESSING";
      color = Colors.amber;
    } else if (_isSpeaking) {
      text = "COACH IS SPEAKING";
      color = Colors.green;
    }
    
    return Column(
      children: [
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ).animate(key: ValueKey(text)).fadeIn().slideY(begin: 0.2),
        const SizedBox(height: 8),
        if (_isProcessing)
          const SizedBox(
            width: 40,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation(Colors.amber),
              minHeight: 2,
            ),
          ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCallButton(
          icon: Icons.mic_off_rounded,
          color: Colors.white24,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 32),
        GestureDetector(
          onTap: () {
            if (_isListening) {
              _speechToText.stop();
              setState(() => _isListening = false);
            } else {
              _startListening();
            }
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening ? Colors.red : AppColors.primaryAccent,
              boxShadow: [
                BoxShadow(
                  color: (_isListening ? Colors.red : AppColors.primaryAccent).withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              _isListening ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 32),
        _buildCallButton(
          icon: Icons.volume_up_rounded,
          color: Colors.white24,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildCallButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
