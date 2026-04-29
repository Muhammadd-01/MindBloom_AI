import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';

/// Daily report screen showing detailed analysis breakdown and smart feedback
class ReportScreen extends ConsumerWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(analysisProvider);
    final result = analysis.currentResult;
    final feedback = analysis.feedback;
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: SafeArea(
          child: result == null
              ? _buildNoDataState(context, isDarkMode)
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildHeader(context, isDarkMode),
                      const SizedBox(height: 24),
                      _buildScoreSection(result, isDarkMode),
                      const SizedBox(height: 20),
                      _buildDetailCards(result, isDarkMode),
                      const SizedBox(height: 20),
                      _buildInputPreview(result, isDarkMode),
                      const SizedBox(height: 20),
                      if (feedback.isNotEmpty) _buildFeedbackSection(feedback, isDarkMode),
                      const SizedBox(height: 20),
                      _buildKeywords(result, isDarkMode),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildNoDataState(BuildContext context, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📊', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 20),
          Text(
            'No Analysis Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Record your thoughts first to see your report',
            style: TextStyle(
              fontSize: 15,
              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.glassWhite : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
              boxShadow: isDarkMode ? null : [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
              ],
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Analysis Report',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            ),
          ),
        ),
        Text(
          DateFormat('MMM d, HH:mm').format(DateTime.now()),
          style: TextStyle(
            fontSize: 13, 
            color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSection(AnalysisResult result, bool isDarkMode) {
    Color scoreColor;
    String emoji;
    if (result.positivityScore >= 70) {
      scoreColor = AppColors.positive;
      emoji = '🌟';
    } else if (result.positivityScore >= 40) {
      scoreColor = AppColors.highlight;
      emoji = '⚡';
    } else {
      scoreColor = AppColors.negative;
      emoji = '🌧️';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withOpacity(0.15),
            isDarkMode ? AppColors.cardBg : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scoreColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(isDarkMode ? 0.1 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: result.positivityScore.toDouble()),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => Text(
              '${value.toInt()}',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ),
          Text(
            'Positivity Score',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCards(AnalysisResult result, bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _detailCard(
            'Sentiment',
            result.sentiment.toUpperCase(),
            _sentimentIcon(result.sentiment),
            _sentimentColor(result.sentiment),
            isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _detailCard(
            'Tone',
            result.tone.toUpperCase(),
            _toneIcon(result.tone),
            AppColors.secondaryAccent,
            isDarkMode,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _detailCard(
            'Input',
            result.inputType.toUpperCase(),
            result.inputType == 'voice'
                ? Icons.mic_rounded
                : Icons.edit_rounded,
            AppColors.highlight,
            isDarkMode,
          ),
        ),
      ],
    );
  }

  Widget _detailCard(String label, String value, IconData icon, Color color, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
        boxShadow: isDarkMode ? null : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11, 
              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPreview(AnalysisResult result, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
        boxShadow: isDarkMode ? null : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded,
                  color: AppColors.secondaryAccent.withOpacity(0.7), size: 20),
              const SizedBox(width: 8),
              Text(
                'Your Input',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.inputText,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(List<FeedbackItem> feedback, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            const Text('MindBloom Analysis', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 14),
        ...feedback.map((item) => _feedbackCard(item, isDarkMode)),
      ],
    );
  }

  Widget _feedbackCard(FeedbackItem item, bool isDarkMode) {
    Color cardColor;
    switch (item.type) {
      case 'breathing':
        cardColor = AppColors.secondaryAccent;
        break;
      case 'islamic':
        cardColor = AppColors.positive;
        break;
      case 'reflection':
        cardColor = AppColors.highlight;
        break;
      default:
        cardColor = AppColors.primaryAccent;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withOpacity(0.1),
            isDarkMode ? AppColors.glassWhite : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardColor.withOpacity(0.2)),
        boxShadow: isDarkMode ? null : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cardColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.description,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
              height: 1.5,
            ),
          ),
          if (item.quranVerse != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.positive.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.positive.withOpacity(0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.quranVerse!,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppColors.positive,
                      height: 1.5,
                    ),
                  ),
                  if (item.hadith != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      item.hadith!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKeywords(AnalysisResult result, bool isDarkMode) {
    if (result.keywords.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
        boxShadow: isDarkMode ? null : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected Keywords',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.keywords.map((keyword) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.secondaryAccent.withOpacity(0.25),
                  ),
                ),
                child: Text(
                  '#$keyword',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryAccent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _sentimentIcon(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return Icons.sentiment_very_satisfied_rounded;
      case 'negative':
        return Icons.sentiment_very_dissatisfied_rounded;
      default:
        return Icons.sentiment_neutral_rounded;
    }
  }

  Color _sentimentColor(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return AppColors.positive;
      case 'negative':
        return AppColors.negative;
      default:
        return AppColors.highlight;
    }
  }

  IconData _toneIcon(String tone) {
    switch (tone) {
      case 'calm':
        return Icons.spa_rounded;
      case 'joy':
        return Icons.celebration_rounded;
      case 'stress':
        return Icons.warning_rounded;
      case 'sadness':
        return Icons.cloud_rounded;
      case 'motivation':
        return Icons.rocket_launch_rounded;
      default:
        return Icons.waves_rounded;
    }
  }
}
