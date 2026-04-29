import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../record/screens/record_screen.dart';
import '../../insights/screens/insights_screen.dart';
import '../../psychology/screens/psychological_screen.dart';
import '../../settings/screens/settings_screen.dart';

/// Main app shell with bottom navigation bar
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final _screens = [
    const DashboardScreen(),
    const InsightsScreen(),
    const PsychologicalScreen(), // Index 2
    const RecordScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initial data loading for existing session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authStateProvider);
      if (auth.user != null) {
        ref.read(dashboardProvider.notifier).loadDashboard(auth.user!.uid);
        ref.read(assessmentProvider.notifier).loadHistory(auth.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);

    // Reactive data loading for future changes
    ref.listen(authStateProvider, (previous, next) {
      if (next.user != null && previous?.user == null) {
        ref.read(dashboardProvider.notifier).loadDashboard(next.user!.uid);
        ref.read(assessmentProvider.notifier).loadHistory(next.user!.uid);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: IndexedStack(
        index: currentTab,
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.secondaryBg.withOpacity(0.8),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.glassBorder.withOpacity(0.1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                   Expanded(
                    child: _NavItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Home',
                      isSelected: currentTab == 0,
                      onTap: () => ref.read(currentTabProvider.notifier).state = 0,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.insights_rounded,
                      label: 'Insights',
                      isSelected: currentTab == 1,
                      onTap: () => ref.read(currentTabProvider.notifier).state = 1,
                    ),
                  ),
                  const SizedBox(width: 40), // Space for center FAB
                  Expanded(
                    child: _NavItem(
                      icon: Icons.psychology_rounded,
                      label: 'Psychology',
                      isSelected: currentTab == 2,
                      onTap: () => ref.read(currentTabProvider.notifier).state = 2,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      isSelected: currentTab == 4,
                      onTap: () => ref.read(currentTabProvider.notifier).state = 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: _RecordNavItem(
          isSelected: currentTab == 3,
          onTap: () => _showRecordMenu(context, ref),
        ),
      ),
    );
  }

  void _showRecordMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.secondaryBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: AppColors.glassBorder.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'How would you like to reflect?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _MenuOption(
                    icon: Icons.edit_note_rounded,
                    label: 'Journal',
                    color: AppColors.primaryAccent,
                    onTap: () {
                      ref.read(recordTabProvider.notifier).state = 0;
                      ref.read(currentTabProvider.notifier).state = 3; // Record is now index 3
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _MenuOption(
                    icon: Icons.mic_rounded,
                    label: 'Voice',
                    color: AppColors.secondaryAccent,
                    onTap: () {
                      ref.read(recordTabProvider.notifier).state = 1;
                      ref.read(currentTabProvider.notifier).state = 3; // Record is now index 3
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard nav item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryAccent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.primaryAccent : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primaryAccent : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Special center Record button with gradient
class _RecordNavItem extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _RecordNavItem({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryAccent.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }
}
