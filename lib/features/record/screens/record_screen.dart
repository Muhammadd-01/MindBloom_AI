import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import '../../report/screens/report_screen.dart';
import '../../subscription/screens/subscription_screen.dart';

/// Screen for recording voice, journaling, and mood selection
class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen>
    with TickerProviderStateMixin {
  final _journalController = TextEditingController();
  MoodType? _selectedMood;
  bool _isRecording = false;
  String _recordedText = '';
  String? _attachedImageUrl;
  bool _isUploadingImage = false;
  int get _selectedInputTab => ref.watch(recordTabProvider);
  void _setInputTab(int index) => ref.read(recordTabProvider.notifier).state = index;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isFocusMode = false;
  String _currentVibe = 'Neutral';
  Color _vibeColor = Colors.grey;
  int _currentPromptIndex = 0;

  final List<String> _prompts = [
    'How are you feeling today? Write freely...',
    'What is one thing that made you smile today?',
    'Describe a challenge you faced and how you handled it.',
    'What are you most grateful for in this moment?',
    'If you could send a message to your future self, what would it be?',
  ];

  final List<double> _waveformValues = List.generate(30, (_) => 0.1);
  late AnimationController _waveformController;
  
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4), // Calm mindfulness breathing
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _journalController.addListener(_onTextChanged);
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) => print('Speech Error: $error'),
        onStatus: (status) => print('Speech Status: $status'),
      );
      if (mounted) setState(() {});
    } catch (e) {
      print('Speech recognition not available: $e');
      _speechEnabled = false;
      if (mounted) setState(() {});
    }
  }

  void _onTextChanged() {
    final text = _journalController.text.toLowerCase();
    if (text.isEmpty) {
      setState(() {
        _currentVibe = 'Neutral';
        _vibeColor = Colors.grey;
      });
      return;
    }

    // Simple real-time sentiment "Vibe Check" simulation
    final positiveWords = ['happy', 'great', 'good', 'love', 'amazing', 'smile', 'grateful', 'peace'];
    final negativeWords = ['sad', 'bad', 'angry', 'hate', 'stressed', 'tired', 'worried', 'difficult'];
    
    int posCount = positiveWords.where((w) => text.contains(w)).length;
    int negCount = negativeWords.where((w) => text.contains(w)).length;

    setState(() {
      if (!_isFocusMode && _journalController.text.length > 5) _isFocusMode = true;
      if (posCount > negCount) {
        _currentVibe = 'Positive';
        _vibeColor = AppColors.primaryAccent;
      } else if (negCount > posCount) {
        _currentVibe = 'Difficult';
        _vibeColor = AppColors.negative;
      } else {
        _currentVibe = 'Reflective';
        _vibeColor = AppColors.secondaryAccent;
      }
    });
  }

  @override
  void dispose() {
    _journalController.dispose();
    _pulseController.dispose();
    _waveformController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    try {
      if (!_speechEnabled) {
        final status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) return;
        _speechEnabled = await _speechToText.initialize();
        if (!_speechEnabled) return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition is not linked yet. Please perform a full rebuild.')),
      );
      return;
    }

    if (_isRecording) {
      await _speechToText.stop();
      setState(() {
        _isRecording = false;
        // Reset waveform values
        for (int i = 0; i < _waveformValues.length; i++) {
          _waveformValues[i] = 0.1;
        }
      });
    } else {
      setState(() {
        _isRecording = true;
        _recordedText = '';
      });
      
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _recordedText = result.recognizedWords;
          });
        },
        onSoundLevelChange: (level) {
          if (_isRecording) {
            setState(() {
              // Shift values to the left and add new sound level info
              for (int i = 0; i < _waveformValues.length - 1; i++) {
                _waveformValues[i] = _waveformValues[i + 1];
              }
              // Normalized level (usually -10 to 10 for speech_to_text)
              double normalized = (level + 2).clamp(0.1, 10.0) / 10.0;
              _waveformValues[_waveformValues.length - 1] = normalized;
            });
          }
        },
        listenFor: const Duration(minutes: 5),
        pauseFor: const Duration(seconds: 10),
      );
    }
  }

  Future<void> _analyzeInput() async {
    String inputText = '';
    String inputType = 'journal';

    if (_selectedInputTab == 0) {
      inputText = _journalController.text.trim();
      inputType = 'journal';
    } else {
      inputText = _recordedText;
      inputType = 'voice';
    }

    if (_selectedMood != null) {
      inputText += ' [Mood: ${_selectedMood!.label}]';
    }

    if (inputText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some input first')),
      );
      return;
    }

    final user = ref.read(authStateProvider).user;
    final dashboard = ref.read(dashboardProvider);
    final currentEntries = dashboard.todayReport?.entriesCount ?? 0;
    final limit = user?.subscriptionTier.dailyLimit ?? 3;

    if (currentEntries >= limit) {
      _showPremiumPaywall();
      return;
    }

    await ref.read(analysisProvider.notifier).analyze(
      text: inputText,
      userId: user?.uid ?? 'demo',
      inputType: inputType,
      imageUrl: _attachedImageUrl,
    );

    if (mounted) {
      HapticFeedback.heavyImpact();
      final analysisState = ref.read(analysisProvider);
      if (analysisState.error != null && analysisState.error!.contains('limit')) {
        _showPremiumPaywall();
      } else if (analysisState.currentResult != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ReportScreen(),
          ),
        );
      }
    }
  }

  void _showPremiumPaywall() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.secondaryBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          gradient: AppColors.darkGradient,
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 40),
            const Text('🌱', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            const Text(
              'Daily Limit Reached',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'You\'ve completed your 3 reflections for today. Consistency is great! Upgrade to Bloom or Forest to continue growing without limits.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.5),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('View Growing Plans', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Continue Free', style: TextStyle(color: Colors.white54)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(analysisProvider);
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;
    final theme = Theme.of(context);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Container(
            decoration: BoxDecoration(
              gradient: isDarkMode ? AppColors.darkGradient : AppColors.lightGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_isFocusMode) ...[
                      Text(
                        'Record Your Thoughts',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Express yourself through voice or text',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildPromptCarousel(isDarkMode),
                      const SizedBox(height: 24),
                    ],
                    if (_isFocusMode)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Deep Reflection',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _isFocusMode = false),
                            child: const Text('Exit Focus'),
                          ),
                        ],
                      ).animate().fadeIn(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (!_isFocusMode) 
                          Expanded(
                            flex: 3,
                            child: _buildInputToggle(isDarkMode),
                          ),
                        if (!_isFocusMode) const SizedBox(width: 8),
                        _buildPassiveToggle(ref, isDarkMode),
                        const SizedBox(width: 6),
                        Flexible(
                          flex: 2,
                          child: _buildGrowthIndicator(isDarkMode),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (ref.watch(recordTabProvider) == 0)
                      _buildJournalInput(isDarkMode)
                    else
                      _buildVoiceInput(isDarkMode),
                    const SizedBox(height: 24),
                    _buildMoodSelector(isDarkMode),
                    const SizedBox(height: 32),
                    // Analyze button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryAccent.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: analysisState.isAnalyzing ? null : _analyzeInput,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: analysisState.isAnalyzing
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'AI IS PROCESSING...',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_awesome_rounded, size: 24),
                                    SizedBox(width: 12),
                                    Text(
                                      'BEGIN ANALYSIS',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms).scale(delay: 100.ms, begin: const Offset(0.95, 0.95)),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(),
        if (analysisState.isAnalyzing) _buildNeuralOverlay(isDarkMode),
      ],
    );
  }

  Widget _buildPassiveToggle(WidgetRef ref, bool isDarkMode) {
    final isPassive = ref.watch(settingsProvider).isPassiveMode;
    return GestureDetector(
      onTap: () {
        ref.read(settingsProvider.notifier).togglePassiveMode();
        HapticFeedback.mediumImpact();
      },
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isPassive ? Colors.green.withValues(alpha: 0.1) : (isDarkMode ? AppColors.cardBg : AppColors.cardBgLightGray.withValues(alpha: 0.3)),
          shape: BoxShape.circle,
          border: Border.all(color: isPassive ? Colors.green.withValues(alpha: 0.5) : (isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark)),
        ),
        child: Icon(
          isPassive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          size: 16,
          color: isPassive ? Colors.green : (isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark),
        ),
      ),
    );
  }

  Widget _buildNeuralOverlay(bool isDarkMode) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Neural Grid Animation
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(12, (index) {
                    return RotationTransition(
                      turns: AlwaysStoppedAnimation(index / 12),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(color: AppColors.primaryAccent.withValues(alpha: 0.5), blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).animate(onPlay: (controller) => controller.repeat())
                    .rotate(duration: 3.seconds, curve: Curves.linear),
                  
                  // Inner pulsing brain icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryAccent.withValues(alpha: 0.1),
                      border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.psychology_rounded, size: 40, color: AppColors.primaryAccent),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1.seconds),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'NEURAL ENGINE ANALYZING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeOut(duration: 800.ms),
            const SizedBox(height: 12),
            Text(
              'Decrypting emotional resonance and behavior patterns...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildGrowthIndicator(bool isDarkMode) {
    final user = ref.watch(authStateProvider).user;
    final dashboard = ref.watch(dashboardProvider);
    final count = dashboard.todayReport?.entriesCount ?? 0;
    final limit = user?.subscriptionTier.dailyLimit ?? 3;
    final color = count >= limit ? AppColors.negative : AppColors.primaryAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_graph_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$count/$limit Growth',
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputToggle(bool isDarkMode) {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBg.withValues(alpha: 0.5) : AppColors.cardBgLightGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
      ),
      child: Stack(
        children: [
          // Sliding Background
          AnimatedAlign(
            duration: 300.ms,
            curve: Curves.easeInOutBack,
            alignment: ref.watch(recordTabProvider) == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryAccent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tab Icons/Labels
          Row(
            children: [
              _toggleTab('📝 Journal', 0, isDarkMode),
              _toggleTab('🎙️ Voice', 1, isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, int index, bool isDarkMode) {
    final isSelected = _selectedInputTab == index;
    final user = ref.read(authStateProvider).user;
    final isVoiceLocked = index == 1 && user?.subscriptionTier == SubscriptionTier.seedling;
    
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (isVoiceLocked) {
             _showPremiumPaywall();
          } else {
            _setInputTab(index);
            HapticFeedback.lightImpact();
          }
        },
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark),
                ),
              ),
              if (isVoiceLocked) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.lock_rounded, 
                  size: 12, 
                  color: isDarkMode ? AppColors.secondaryAccent : AppColors.textSecondaryDark.withValues(alpha: 0.5)
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJournalInput(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBg.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _journalController,
                maxLines: _isFocusMode ? 15 : 8,
                style: TextStyle(
                  color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                  fontSize: 16,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: _prompts[_currentPromptIndex],
                  hintStyle: TextStyle(
                    color: (isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark).withValues(alpha: 0.4)
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(24),
                ),
              ),
              if (_journalController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _vibeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 14, color: _vibeColor),
                            const SizedBox(width: 6),
                            Text(
                              'Vibe: $_currentVibe',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _vibeColor),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_journalController.text.trim().split(RegExp(r'\s+')).length} words',
                        style: TextStyle(
                          fontSize: 12, 
                          color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Colors.white12),
              
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _buildActionButton(
                      icon: Icons.add_photo_alternate_rounded,
                      label: _attachedImageUrl != null ? 'Change Photo' : 'Add Image',
                      onPressed: _isUploadingImage ? null : _pickJournalImage,
                      isDarkMode: isDarkMode,
                    ),
                    const Spacer(),
                    if (_attachedImageUrl != null)
                      _buildImagePreview(isDarkMode),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isDarkMode,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: AppColors.primaryAccent),
      label: Text(
        label,
        style: TextStyle(
          color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: Colors.white.withValues(alpha: isDarkMode ? 0.05 : 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildImagePreview(bool isDarkMode) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryAccent, width: 2),
      ),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(_attachedImageUrl!, fit: BoxFit.cover, width: 44, height: 44),
          ),
          GestureDetector(
            onTap: () => setState(() => _attachedImageUrl = null),
            child: Container(
              padding: const EdgeInsets.all(2),
              margin: const EdgeInsets.all(1),
              decoration: const BoxDecoration(color: AppColors.negative, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 8, color: Colors.white),
            ),
          ),
        ],
      ),
    ).animate().scale();
  }

  Future<void> _pickJournalImage() async {
  setState(() => _isUploadingImage = true);
  try {
    final url = await ref.read(authStateProvider.notifier).uploadJournalImage(ImageSource.gallery);
    setState(() {
      _attachedImageUrl = url;
      _isUploadingImage = false;
    });
  } catch (e) {
    setState(() => _isUploadingImage = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }
}

  Widget _buildVoiceInput(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBg.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _isRecording ? 'Listening Intently...' : 'Tap to Speak',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _isRecording ? 'MindBloom is analyzing your tone and words...' : 'Express yourself. Your voice remains private.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 48),
          
          // Recording Button UI
          Center(
            child: GestureDetector(
              onTap: _toggleRecording,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 80 * (_isRecording ? _pulseAnimation.value : 1.0),
                    height: 80 * (_isRecording ? _pulseAnimation.value : 1.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _isRecording
                          ? const LinearGradient(
                              colors: [AppColors.negative, Color(0xFFDC2626)],
                            )
                          : AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording
                                  ? AppColors.negative
                                  : AppColors.primaryAccent)
                              .withValues(alpha: 0.4),
                          blurRadius: 24,
                          spreadRadius: _isRecording ? 4 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isRecording ? 'TAP TO STOP' : 'TAP TO RECORD',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              color: _isRecording ? AppColors.negative : (isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelector(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How are you feeling?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'MindBloom captures your thoughts and guides you toward positivity.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: MoodType.values.map((mood) {
            final isSelected = _selectedMood == mood;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedMood = isSelected ? null : mood;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryAccent.withValues(alpha: 0.15)
                      : (isDarkMode ? AppColors.glassWhite : Colors.white),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryAccent
                        : (isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isDarkMode ? null : [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      mood.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected
                            ? AppColors.primaryAccent
                            : (isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPromptCarousel(bool isDarkMode) {
    return InkWell(
      onTap: () {
        setState(() {
          _currentPromptIndex = (_currentPromptIndex + 1) % _prompts.length;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.secondaryAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondaryAccent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded, color: AppColors.secondaryAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Prompt: Tap to change guidelines',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryAccent,
                ),
              ),
            ),
            const Icon(Icons.refresh_rounded, color: AppColors.secondaryAccent, size: 18),
          ],
        ),
      ),
    );
  }
}
