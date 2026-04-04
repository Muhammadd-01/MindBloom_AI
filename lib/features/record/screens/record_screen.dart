import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import '../../report/screens/report_screen.dart';

/// Screen for recording voice, journaling, and mood selection
class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen>
    with SingleTickerProviderStateMixin {
  final _journalController = TextEditingController();
  MoodType? _selectedMood;
  bool _isRecording = false;
  String _recordedText = '';
  String? _attachedImageUrl;
  bool _isUploadingImage = false;
  int _selectedInputTab = 0; // 0=Journal, 1=Voice
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _journalController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    setState(() => _isRecording = !_isRecording);

    if (!_isRecording) {
      // Simulate speech-to-text conversion
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _recordedText =
            'Today I felt really grateful for the little things. '
            'Had a productive morning and spent quality time with family. '
            'Work was challenging but I managed to stay positive.';
      });
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
    await ref.read(analysisProvider.notifier).analyze(
      text: inputText,
      userId: user?.uid ?? 'demo',
      inputType: inputType,
      imageUrl: _attachedImageUrl,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReportScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(analysisProvider);
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
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
                const SizedBox(height: 16),
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
                _buildInputToggle(isDarkMode),
                const SizedBox(height: 24),
                if (_selectedInputTab == 0)
                  _buildJournalInput(isDarkMode)
                else
                  _buildVoiceInput(isDarkMode),
                const SizedBox(height: 24),
                _buildMoodSelector(isDarkMode),
                const SizedBox(height: 32),
                // Analyze button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: analysisState.isAnalyzing ? null : _analyzeInput,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Analyzing...'),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.psychology_rounded, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'Analyze My Input',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputToggle(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBg : AppColors.cardBgLightGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
      ),
      child: Row(
        children: [
          _toggleTab('📝 Journal', 0, isDarkMode),
          _toggleTab('🎙️ Voice', 1, isDarkMode),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, int index, bool isDarkMode) {
    final isSelected = _selectedInputTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedInputTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : (isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJournalInput(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBg : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
        boxShadow: isDarkMode ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _journalController,
            maxLines: 8,
            style: TextStyle(
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
              fontSize: 15,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: 'How are you feeling today? Write freely...',
              hintStyle: TextStyle(
                color: (isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark).withValues(alpha: 0.6)
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
      if (_attachedImageUrl != null || _isUploadingImage)
        Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryAccent, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _isUploadingImage 
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : Image.network(_attachedImageUrl!, fit: BoxFit.cover),
                ),
              ),
              if (!_isUploadingImage)
                GestureDetector(
                  onTap: () => setState(() => _attachedImageUrl = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.negative,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(left: 10, bottom: 10),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primaryAccent),
              onPressed: _isUploadingImage ? null : _pickJournalImage,
            ),
            if (!_isUploadingImage && _attachedImageUrl == null)
              Text(
                'Add Photo',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBg : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
        boxShadow: isDarkMode ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Recording button with pulse animation
          GestureDetector(
            onTap: _toggleRecording,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 100 * (_isRecording ? _pulseAnimation.value : 1.0),
                  height: 100 * (_isRecording ? _pulseAnimation.value : 1.0),
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
                    size: 44,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isRecording ? 'Recording... Tap to stop' : 'Tap to start recording',
            style: TextStyle(
              fontSize: 15,
              color: _isRecording ? AppColors.negative : (isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_recordedText.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primaryAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Transcribed Text',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recordedText,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        Text(
          'Select your current mood (optional)',
          style: TextStyle(
            fontSize: 13, 
            color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark
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
}
