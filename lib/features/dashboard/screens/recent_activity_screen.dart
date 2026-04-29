import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import 'package:intl/intl.dart';

class RecentActivityScreen extends ConsumerWidget {
  const RecentActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final analyses = dashboardState.recentAnalyses;
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.primaryBg : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Activity History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: analyses.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_toggle_off_rounded,
                      color: isDarkMode ? Colors.white24 : Colors.black12,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No activity recorded yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: analyses.length,
                itemBuilder: (context, index) {
                  return _activityTile(analyses[index], isDarkMode);
                },
              ),
      ),
    );
  }

  Widget _activityTile(AnalysisResult analysis, bool isDarkMode) {
    final isPositive = analysis.sentiment == 'positive';
    final color = isPositive
        ? AppColors.positive
        : (analysis.sentiment == 'negative' ? AppColors.negative : AppColors.highlight);
    final icon = analysis.inputType == 'voice' ? Icons.mic_rounded : Icons.edit_note_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark,
        ),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.inputText.isNotEmpty ? analysis.inputText : '${analysis.inputType.toUpperCase()} Reflection',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, h:mm a').format(analysis.analyzedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${analysis.positivityScore}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
