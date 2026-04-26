import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import '../../settings/screens/notifications_screen.dart';
import '../../gamification/screens/behavior_game_screen.dart';
import 'recent_activity_screen.dart';
import '../../../core/services/local_ai_engine.dart';

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
          /// AI chatbot coach powered by MindBloom AI
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
                        _buildPassiveAIBanner(ref, isDarkMode),
                        _buildHeader(context, user, isDarkMode),
                        const SizedBox(height: 20),
                        _buildDailyNudge(context, user, isDarkMode).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                        const SizedBox(height: 16),
                        /// Service for communicating with MindBloom AI and Backend
                        _buildScoreCard(dashboard.todayReport, isDarkMode).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                        const SizedBox(height: 20),
                        _buildAICoachCard(isDarkMode).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                        const SizedBox(height: 20),
                        _buildStreakCard(user, isDarkMode).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                        const SizedBox(height: 20),
                        _buildWeeklyChart(dashboard.weeklyInsights, isDarkMode).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                        const SizedBox(height: 20),
                        _buildRecentActivity(context, dashboard.recentAnalyses, isDarkMode).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                        const SizedBox(height: 20),
                        _buildGameCard(context, isDarkMode).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPassiveAIBanner(WidgetRef ref, bool isDarkMode) {
    final isPassive = ref.watch(settingsProvider).isPassiveMode;
    if (!isPassive) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryAccent.withValues(alpha: 0.1),
            AppColors.secondaryAccent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.green, blurRadius: 4, spreadRadius: 1),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 800.ms)
           .tint(color: Colors.greenAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Passive AI Monitoring Active',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryAccent,
                  ),
                ),
                Text(
                  'MindBloom AI is subtly observing behavior patterns...',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'LIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.green.withValues(alpha: 0.7),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
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

  Widget _buildDailyNudge(BuildContext context, UserModel? user, bool isDarkMode) {
    // Calculate level progress based on 200 points per level as per AuthNotifier
    final currentLevel = user?.level ?? 1;
    final totalPoints = user?.totalPoints ?? 0;
    final pointsForThisLevel = totalPoints % 200;
    final progress = pointsForThisLevel / 200.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppColors.glassDecoration(isDarkMode: isDarkMode),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.amberGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.highlight.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level $currentLevel Journey',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.highlight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    AnimatedContainer(
                      duration: 1.seconds,
                      height: 8,
                      width: MediaQuery.of(context).size.width * 0.5 * progress,
                      decoration: BoxDecoration(
                        gradient: AppColors.amberGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.highlight.withValues(alpha: 0.4),
                            blurRadius: 6,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user, bool isDarkMode) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.blueGradient,
            shape: BoxShape.circle,
            image: (user != null && user.photoUrl.isNotEmpty)
                ? DecorationImage(
                    image: NetworkImage(user.photoUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: (user == null || user.photoUrl.isEmpty)
            ? Center(
                child: Text(
                  (user != null && user.displayName.isNotEmpty)
                      ? user.displayName[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${user?.displayName.isNotEmpty == true ? user!.displayName : 'Positivity User'}! 👋',
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
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          child: Container(
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
        ),
      ],
    );
  }

  Widget _buildGameCard(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryAccent,
            AppColors.primaryAccent.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Mindset Challenge',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Test your logic and earn +EXP',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BehaviorGameScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Play Now', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Icon(Icons.psychology_rounded, size: 64, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildScoreCard(DailyReport? report, bool isDarkMode) {
    final score = report?.averageScore ?? 0;
    final sentiment = report?.dominantSentiment ?? 'neutral';
    final hasData = report != null && report.entriesCount > 0;

    Color scoreColor;
    if (!hasData) {
      scoreColor = AppColors.textSecondary;
    } else if (score >= 70) {
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
            scoreColor.withValues(alpha: 0.2),
            isDarkMode ? AppColors.cardBg.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.9),
            scoreColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: isDarkMode ? 0.2 : 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primaryAccent,
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                .scale(duration: 1.seconds, curve: Curves.easeInOut)
                .fadeOut(duration: 1.seconds, curve: Curves.easeInOut),
              const SizedBox(width: 8),
              Text(
                hasData ? "Today's Positivity Score" : "Waiting for First Entry",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Animated score
          if (hasData)
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
            )
          else
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkMode ? AppColors.cardBgLight : AppColors.cardBgLightGray,
              ),
              child: const Icon(Icons.psychology_rounded, size: 64, color: AppColors.textSecondary),
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

  Widget _buildStreakCard(UserModel? user, bool isDarkMode) {
    final streak = user?.streak ?? 0;
    final level = user?.level ?? 1;
    final points = user?.totalPoints ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppColors.glassDecoration(isDarkMode: isDarkMode),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _streakItem('🔥', '$streak', 'Streak', isDarkMode, AppColors.roseGradient),
          Container(
            width: 1.5,
            height: 45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, isDarkMode ? Colors.white24 : Colors.black12, Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          _streakItem('⭐', 'Lvl $level', 'Level', isDarkMode, AppColors.purpleGradient),
          Container(
            width: 1.5,
            height: 45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, isDarkMode ? Colors.white24 : Colors.black12, Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          _streakItem('💎', '$points', 'Points', isDarkMode, AppColors.blueGradient),
        ],
      ),
    );
  }

  Widget _streakItem(String emoji, String value, String label, bool isDarkMode, LinearGradient gradient) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient.colors.map((c) => c.withValues(alpha: 0.1)).toList(),
              begin: gradient.begin,
              end: gradient.end,
            ),
            shape: BoxShape.circle,
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11, 
            fontWeight: FontWeight.w500,
            color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(List<InsightData> data, bool isDarkMode) {
    // If data is empty, generate 7 days of 0s to show the trend starting at zero
    final displayData = data.isEmpty 
      ? List.generate(7, (index) => InsightData(
          date: DateTime.now().subtract(Duration(days: 6 - index)),
          score: 0,
          sentiment: 'Neutral',
        ))
      : data;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                ),
              ),
              if (data.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Getting Started',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
            ],
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
                        if (index >= 0 && index < displayData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('E').format(displayData[index].date),
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
                    spots: displayData.asMap().entries.map((e) {
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
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Text(
                  'Your weekly trend will start appearing here!',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDarkMode ? AppColors.textSecondary.withValues(alpha: 0.7) : AppColors.textSecondaryDark.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAICoachCard(bool isDarkMode) {
    return FutureBuilder<String>(
      future: MindBloomLocalAIEngine.chatWithCoach('Give me a one-sentence behavioral positivity tip for today.'),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final tip = snapshot.data ?? 'Believe in yourself and take one small step towards your goal today.';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.cardBg : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryAccent.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'MindBloom AI Coach',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  if (isLoading)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                isLoading ? 'Thinking...' : '"$tip"',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                  color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(
      BuildContext context, List<AnalysisResult> analyses, bool isDarkMode) {
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
            if (analyses.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecentActivityScreen(),
                    ),
                  );
                },
                child: Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (analyses.isEmpty)
           Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.glassWhite : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history_toggle_off_rounded,
                  color: isDarkMode ? Colors.white24 : Colors.black12,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'No activity yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your recent reflections and AI insights will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          )
        else
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
