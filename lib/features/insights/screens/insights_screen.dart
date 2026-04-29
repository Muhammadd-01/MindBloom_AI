import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';

/// Insights screen with weekly/monthly charts, behavior summary, and gamification
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  int _selectedPeriod = 0; // 0=Weekly, 1=Monthly

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final streakInfo = dashboardState.streakInfo;
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;

    final weeklyData = dashboardState.weeklyInsights;
    final monthlyData = dashboardState.monthlyInsights;
    final currentData = _selectedPeriod == 0 ? weeklyData : monthlyData;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.primaryBg : Colors.white,
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
                  'Insights',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your positivity journey',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                  ),
                ),

                const SizedBox(height: 24),

                // Period toggle
                _buildPeriodToggle(isDarkMode),

                const SizedBox(height: 20),

                // Line Chart
                _buildLineChart(currentData, isDarkMode),

                const SizedBox(height: 20),

                // Bar Chart
                _buildBarChart(weeklyData, monthlyData, isDarkMode),

                const SizedBox(height: 20),

                // Behavior Summary
                _buildBehaviorSummary(currentData, isDarkMode),

                const SizedBox(height: 20),

                // Gamification Section
                _buildGamification(streakInfo, isDarkMode),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodToggle(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
      ),
      child: Row(
        children: [
          _periodTab('Weekly', 0, isDarkMode),
          _periodTab('Monthly', 1, isDarkMode),
        ],
      ),
    );
  }

  Widget _periodTab(String label, int index, bool isDarkMode) {
    final isSelected = _selectedPeriod == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.blueGradient : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected 
                  ? Colors.white 
                  : (isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<InsightData> data, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded,
                  color: AppColors.primaryAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Positivity Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.glassBorder,
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
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _selectedPeriod == 0 ? 1 : 5,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _selectedPeriod == 0
                                  ? DateFormat('E').format(data[idx].date)
                                  : DateFormat('d').format(data[idx].date),
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
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: data.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.score.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: AppColors.primaryAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: _selectedPeriod == 0,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primaryAccent,
                        strokeWidth: 2,
                        strokeColor: AppColors.primaryBg,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryAccent.withOpacity(0.25),
                          AppColors.primaryAccent.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<InsightData> weeklyData, List<InsightData> monthlyData, bool isDarkMode) {
    final data =
        _selectedPeriod == 0 ? weeklyData : monthlyData.take(7).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  color: AppColors.secondaryAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Score Distribution',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.glassBorder,
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
                        final idx = value.toInt();
                        if (idx >= 0 && idx < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('E').format(data[idx].date),
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
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((e) {
                  final score = e.value.score.toDouble();
                  Color barColor;
                  if (score >= 70) {
                    barColor = AppColors.positive;
                  } else if (score >= 40) {
                    barColor = AppColors.highlight;
                  } else {
                    barColor = AppColors.negative;
                  }
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: score,
                        color: barColor,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: isDarkMode ? AppColors.cardBgLight.withOpacity(0.3) : AppColors.cardBgLightGray.withOpacity(0.3),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorSummary(List<InsightData> data, bool isDarkMode) {
    final avgScore =
        data.isEmpty ? 0 : data.map((d) => d.score).reduce((a, b) => a + b) ~/ data.length;
    final positiveCount =
        data.where((d) => d.sentiment == 'positive').length;
    final negativeCount =
        data.where((d) => d.sentiment == 'negative').length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.glassWhite : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Behavior Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 16),
          _summaryRow('Average Score', '$avgScore/100',
              avgScore >= 60 ? AppColors.positive : AppColors.highlight, isDarkMode),
          _summaryRow('Positive Days', '$positiveCount', AppColors.positive, isDarkMode),
          _summaryRow('Negative Days', '$negativeCount', AppColors.negative, isDarkMode),
          _summaryRow('Total Entries', '${data.length}', AppColors.secondaryAccent, isDarkMode),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamification(Map<String, dynamic> streakInfo, bool isDarkMode) {
    final level = streakInfo['level'] ?? 1;
    final points = streakInfo['points'] ?? 0;
    final nextLevel = streakInfo['nextLevelPoints'] ?? 1000;
    final progress = (points / nextLevel).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.highlight.withOpacity(0.1),
            AppColors.glassWhite,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.highlight.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(
                'Gamification',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.amberGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Level $level',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$points / $nextLevel XP',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.highlight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: isDarkMode ? AppColors.cardBgLight : AppColors.cardBgLightGray,
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.highlight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Achievements
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
          _achievement('🔥', 'Streak Master', true, isDarkMode),
          _achievement('📝', 'Daily Writer', true, isDarkMode),
          _achievement('🧘', 'Zen Mode', false, isDarkMode),
          _achievement('💎', 'Premium', false, isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _achievement(String emoji, String label, bool unlocked, bool isDarkMode) {
    return Opacity(
      opacity: unlocked ? 1.0 : 0.35,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppColors.highlight.withOpacity(0.15)
                  : (isDarkMode ? AppColors.cardBgLight : AppColors.cardBgLightGray),
              shape: BoxShape.circle,
              border: Border.all(
                color: unlocked
                    ? AppColors.highlight.withOpacity(0.3)
                    : (isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
