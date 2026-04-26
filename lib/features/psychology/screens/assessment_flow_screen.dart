import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import '../../../core/services/local_ai_engine.dart';

class AssessmentFlowScreen extends ConsumerStatefulWidget {
  final String type;
  const AssessmentFlowScreen({super.key, required this.type});

  @override
  ConsumerState<AssessmentFlowScreen> createState() => _AssessmentFlowScreenState();
}

class _AssessmentFlowScreenState extends ConsumerState<AssessmentFlowScreen> {
  int _currentIndex = 0;
  final Map<String, int> _answers = {};
  bool _isAnalyzing = false;
  final PageController _pageController = PageController();

  late final List<Map<String, dynamic>> _questions;
  late final String _title;

  @override
  void initState() {
    super.initState();
    _initQuestions();
  }

  void _initQuestions() {
    if (widget.type == 'phq9') {
      _title = 'Mood Assessment (PHQ-9)';
      _questions = [
        {'id': 'q1', 'text': 'Little interest or pleasure in doing things?'},
        {'id': 'q2', 'text': 'Feeling down, depressed, or hopeless?'},
        {'id': 'q3', 'text': 'Trouble falling or staying asleep, or sleeping too much?'},
        {'id': 'q4', 'text': 'Feeling tired or having little energy?'},
        {'id': 'q5', 'text': 'Poor appetite or overeating?'},
        {'id': 'q6', 'text': 'Feeling bad about yourself — or that you are a failure or have let yourself or your family down?'},
        {'id': 'q7', 'text': 'Trouble concentrating on things, such as reading the newspaper or watching television?'},
        {'id': 'q8', 'text': 'Moving or speaking so slowly that other people could have noticed? Or the opposite — being so fidgety or restless that you have been moving around a lot more than usual?'},
        {'id': 'q9', 'text': 'Thoughts that you would be better off dead or of hurting yourself in some way?'},
      ];
    } else if (widget.type == 'gad7') {
      _title = 'Anxiety Scan (GAD-7)';
      _questions = [
        {'id': 'q1', 'text': 'Feeling nervous, anxious or on edge?'},
        {'id': 'q2', 'text': 'Not being able to stop or control worrying?'},
        {'id': 'q3', 'text': 'Worrying too much about different things?'},
        {'id': 'q4', 'text': 'Trouble relaxing?'},
        {'id': 'q5', 'text': 'Being so restless that it is hard to sit still?'},
        {'id': 'q6', 'text': 'Becoming easily annoyed or irritable?'},
        {'id': 'q7', 'text': 'Feeling afraid as if something awful might happen?'},
      ];
    } else {
      _title = 'Stress Level (PSS-10)';
      _questions = [
        {'id': 'q1', 'text': 'In the last month, how often have you been upset because of something that happened unexpectedly?'},
        {'id': 'q2', 'text': 'In the last month, how often have you felt that you were unable to control the important things in your life?'},
        {'id': 'q3', 'text': 'In the last month, how often have you felt nervous and "stressed"?'},
        {'id': 'q4', 'text': 'In the last month, how often have you felt confident about your ability to handle your personal problems?'},
        {'id': 'q5', 'text': 'In the last month, how often have you felt that things were going your way?'},
        {'id': 'q6', 'text': 'In the last month, how often have you found that you could not cope with all the things that you had to do?'},
        {'id': 'q7', 'text': 'In the last month, how often have you been able to control irritations in your life?'},
        {'id': 'q8', 'text': 'In the last month, how often have you felt that you were on top of things?'},
        {'id': 'q9', 'text': 'In the last month, how often have you been angered because of things that were outside of your control?'},
        {'id': 'q10', 'text': 'In the last month, how often have you felt difficulties were piling up so high that you could not overcome them?'},
      ];
    }
  }

  void _next(int value) {
    _answers[_questions[_currentIndex]['id']] = value;
    if (_currentIndex < _questions.length - 1) {
      _pageController.nextPage(duration: 300.ms, curve: Curves.easeInOut);
      setState(() => _currentIndex++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _isAnalyzing = true);
    
    // Calculate Score
    int total = _answers.values.reduce((a, b) => a + b);
    
    // PSS-10 has reversed items (4, 5, 7, 8)
    if (widget.type == 'pss10') {
      int reversedItems = 0;
      for (var id in ['q4', 'q5', 'q7', 'q8']) {
        reversedItems += (4 - (_answers[id] ?? 0));
        total -= (_answers[id] ?? 0);
      }
      total += reversedItems;
    }

    String level = '';
    if (widget.type == 'phq9') {
      if (total <= 4) level = 'Minimal';
      else if (total <= 9) level = 'Mild';
      else if (total <= 14) level = 'Moderate';
      else if (total <= 19) level = 'Moderately Severe';
      else level = 'Severe';
    } else if (widget.type == 'gad7') {
      if (total <= 4) level = 'Minimal';
      else if (total <= 9) level = 'Mild';
      else if (total <= 14) level = 'Moderate';
      else level = 'Severe';
    } else {
      if (total <= 13) level = 'Low Stress';
      else if (total <= 26) level = 'Moderate Stress';
      else level = 'High Stress';
    }

    try {
      // Interpret with MindBloom AI
      final prompt = "Analyze these results for a ${widget.type.toUpperCase()} psychological test. Total Score: $total, Level: $level. Questions and answers are: $_answers. Give a brief, supportive behavioral interpretation and 3 actionable tips for improvement. Keep it professional but warm.";
      final interpretation = await MindBloomLocalAIEngine.getRawAIResponse(prompt);

      final user = ref.read(authStateProvider).user!;
      final assessment = PsychologicalAssessment(
        id: '', 
        userId: user.uid,
        type: widget.type,
        totalScore: total,
        resultLevel: level,
        interpretation: interpretation,
        answers: _answers,
        completedAt: DateTime.now(),
      );

      await ref.read(assessmentProvider.notifier).saveAssessment(assessment);
      
      if (mounted) {
        Navigator.pop(context);
        _showResultDialog(assessment);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showResultDialog(PsychologicalAssessment assessment) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondaryBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌟', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Assessment Complete',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Result: ${assessment.resultLevel}',
                style: const TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              assessment.interpretation,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back to Psychology'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDarkMode ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: SafeArea(
          child: _isAnalyzing 
            ? _buildAnalyzingOverlay()
            : Column(
                children: [
                  _buildTopBar(isDarkMode),
                  _buildProgressBar(progress),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildQuestionCard(isDarkMode, index),
                              const SizedBox(height: 40),
                              _buildOptions(index),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: isDarkMode ? Colors.white : AppColors.textPrimaryDark),
          ),
          const SizedBox(width: 8),
          Text(
            _title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: Colors.white10,
          valueColor: const AlwaysStoppedAnimation(AppColors.primaryAccent),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(bool isDarkMode, int index) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          Text(
            'Question ${index + 1} of ${_questions.length}',
            style: const TextStyle(color: AppColors.primaryAccent, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Text(
            _questions[index]['text'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : AppColors.textPrimaryDark,
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildOptions(int index) {
    final options = widget.type == 'pss10' 
      ? ['Never', 'Almost Never', 'Sometimes', 'Fairly Often', 'Very Often']
      : ['Not at all', 'Several days', 'More than half the days', 'Nearly every day'];

    return Column(
      children: List.generate(options.length, (optIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => _next(optIndex),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                elevation: 0,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(options[optIndex], style: const TextStyle(fontSize: 16)),
            ),
          ),
        ).animate().fadeIn(delay: (optIndex * 100).ms);
      }),
    );
  }

  Widget _buildAnalyzingOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryAccent),
          const SizedBox(height: 24),
          const Text(
            'Analyzing Patterns...',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'MindBloom AI is interpreting your responses',
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
