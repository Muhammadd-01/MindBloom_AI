import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import '../../report/screens/report_screen.dart';

/// Main dashboard showing positivity score, insights, and weekly trends
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final user = ref.watch(authStateProvider).user;
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: SafeArea(
          child: dashboard.isLoading
              ? _buildLoadingState(isDarkMode)
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(dashboardProvider.notifier)
                      .refresh(user?.uid ?? 'demo'),
                  color: AppColors.primaryAccent,
                  backgroundColor: isDarkMode ? AppColors.cardBg : Colors.white,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildHeader(user, isDarkMode),
                        const SizedBox(height: 24),
                        _buildScoreCard(dashboard.todayReport, isDarkMode),
                        const SizedBox(height: 20),
                        _buildStreakCard(dashboard.streakInfo, isDarkMode),
                        const SizedBox(height: 20),
                        _buildWeeklyChart(dashboard.weeklyInsights, isDarkMode),
                        const SizedBox(height: 20),
                        _buildSuggestionsCard(dashboard.todayReport, isDarkMode),
                        const SizedBox(height: 20),
                        _buildRecentActivity(context, dashboard.recentAnalyses, isDarkMode),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(
                AppColors.primaryAccent.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your insights...',
            style: TextStyle(
              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserModel? user, bool isDarkMode) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.blueGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              user?.displayName.isNotEmpty == true
                  ? user!.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${user?.displayName ?? 'User'}! 👋',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ),
        // Notification bell
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.glassWhite : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
            boxShadow: isDarkMode ? null : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              )
            ],
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard(DailyReport? report, bool isDarkMode) {
    final score = report?.averageScore ?? 0;
    final sentiment = report?.dominantSentiment ?? 'neutral';

    Color scoreColor;
    if (score >= 70) {
      scoreColor = AppColors.positive;
    } else if (score >= 40) {
      scoreColor = AppColors.highlight;
    } else {
      scoreColor = AppColors.negative;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withValues(alpha: 0.15),
            isDarkMode ? AppColors.cardBg : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scoreColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: isDarkMode ? 0.1 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Today's Positivity Score",
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: 20),
          // Animated score
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score.toDouble()),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      color: isDarkMode ? AppColors.cardBgLight : AppColors.cardBgLightGray,
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: value / 100,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      color: scoreColor,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${value.toInt()}',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        sentiment.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scoreColor.withValues(alpha: 0.8),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _miniStat('Tone', report?.dominantTone ?? '--', Icons.waves_rounded, isDarkMode),
              const SizedBox(width: 24),
              _miniStat('Entries', '${report?.entriesCount ?? 0}', Icons.edit_note_rounded, isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon, bool isDarkMode) {
    return Column(
      children: [
        Icon(icon, color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11, 
            color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard(Map<String, dynamic> streakInfo, bool isDarkMode) {
    final streak = streakInfo['currentStreak'] ?? 0;
    final level = streakInfo['level'] ?? 1;
    final points = streakInfo['points'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _streakItem('🔥', '$streak', 'Day Streak', isDarkMode),
          Container(
            width: 1,
            height: 40,
            color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark,
          ),
          _streakItem('⭐', 'Lvl $level', 'Level', isDarkMode),
          Container(
            width: 1,
            height: 40,
            color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark,
          ),
          _streakItem('💎', '$points', 'Points', isDarkMode),
        ],
      ),
    );
  }

  Widget _streakItem(String emoji, String value, String label, bool isDarkMode) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12, 
            color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(List<InsightData> data, bool isDarkMode) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (value, _) => Text(
                        '${value.toInt()}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('E').format(data[index].date),
                              style: TextStyle(
                                fontSize: 10,
                                color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) {
                      return FlSpot(
                        e.key.toDouble(),
                        e.value.score.toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primaryAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primaryAccent,
                        strokeWidth: 2,
                        strokeColor: isDarkMode ? AppColors.primaryBg : Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryAccent.withValues(alpha: 0.3),
                          AppColors.primaryAccent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => isDarkMode ? AppColors.cardBg : Colors.white,
                    tooltipRoundedRadius: 12,
                    getTooltipItems: (spots) => spots.map((spot) {
                      return LineTooltipItem(
                        'Score: ${spot.y.toInt()}',
                        const TextStyle(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard(DailyReport? report, bool isDarkMode) {
    final suggestions = report?.suggestions ?? [];
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondaryAccent.withValues(alpha: 0.1),
            isDarkMode ? AppColors.glassWhite : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondaryAccent.withValues(alpha: 0.2)),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: AppColors.highlight, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Suggestions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(
      BuildContext context, List<AnalysisResult> analyses, bool isDarkMode) {
    if (analyses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportScreen()),
              ),
              child: const Text(
                'View Report',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...analyses.take(3).map((a) => _activityTile(a, isDarkMode)),
      ],
    );
  }

  Widget _activityTile(AnalysisResult analysis, bool isDarkMode) {
    final isPositive = analysis.sentiment == 'positive';
    final color = isPositive ? AppColors.positive : (analysis.sentiment == 'negative' ? AppColors.negative : AppColors.highlight);
    final icon = analysis.inputType == 'voice' ? Icons.mic_rounded : Icons.edit_note_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
        boxShadow: isDarkMode ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.inputText.length > 50
                      ? '${analysis.inputText.substring(0, 50)}...'
                      : analysis.inputText,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${analysis.sentiment} • ${analysis.tone} • ${DateFormat.jm().format(analysis.analyzedAt)}',
                  style: TextStyle(
                    fontSize: 12, 
                    color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${analysis.positivityScore}',
              style: TextStyle(
                fontSize: 14,
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
