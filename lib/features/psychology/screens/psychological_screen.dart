import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import 'assessment_flow_screen.dart';

class PsychologicalScreen extends ConsumerWidget {
  const PsychologicalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assessmentState = ref.watch(assessmentProvider);
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildHeader(isDarkMode),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader('Available Assessments', isDarkMode),
                    const SizedBox(height: 16),
                    _buildTestCard(
                      context,
                      title: 'Mood Assessment (PHQ-9)',
                      subtitle: 'Screen for depression symptoms',
                      icon: Icons.wb_sunny_rounded,
                      color: AppColors.primaryAccent,
                      type: 'phq9',
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildTestCard(
                      context,
                      title: 'Anxiety Scan (GAD-7)',
                      subtitle: 'Check for anxiety patterns',
                      icon: Icons.psychology_rounded,
                      color: AppColors.secondaryAccent,
                      type: 'gad7',
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildTestCard(
                      context,
                      title: 'Stress Level (PSS-10)',
                      subtitle: 'Measure perceived stress',
                      icon: Icons.bolt_rounded,
                      color: AppColors.highlight,
                      type: 'pss10',
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Recent History', isDarkMode),
                    const SizedBox(height: 16),
                    if (assessmentState.history.isEmpty)
                      _buildEmptyHistory(isDarkMode)
                    else
                      ...assessmentState.history.map((a) => _buildHistoryItem(a, isDarkMode)),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Psychological Screen',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Validated clinical assessments for your well-being',
              style: TextStyle(
                fontSize: 15,
                color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : AppColors.textPrimaryDark,
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String type,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => AssessmentFlowScreen(type: type),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.glassWhite : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : AppColors.textPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
    );
  }

  Widget _buildHistoryItem(PsychologicalAssessment assessment, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBg.withOpacity(0.3) : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getColorForLevel(assessment.resultLevel).withOpacity(0.2),
            radius: 20,
            child: Text(
              assessment.type.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getColorForLevel(assessment.resultLevel),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assessment.resultLevel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : AppColors.textPrimaryDark,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(assessment.completedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Score: ${assessment.totalScore}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No assessments yet',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : AppColors.textPrimaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your first test to see your baseline.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForLevel(String level) {
    switch (level.toLowerCase()) {
      case 'minimal':
      case 'normal':
        return Colors.green;
      case 'mild':
        return Colors.blue;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return AppColors.primaryAccent;
    }
  }
}
