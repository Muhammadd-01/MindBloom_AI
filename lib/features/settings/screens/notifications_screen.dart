import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/models.dart';
import 'settings_screen.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.primaryBg : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, 
            color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(notificationProvider.notifier).clearAll();
              },
              child: const Text('Clear All', style: TextStyle(color: AppColors.primaryAccent)),
            ),
          IconButton(
            icon: Icon(Icons.settings_outlined, 
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: notifications.isEmpty
            ? _buildEmptyState(isDarkMode)
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationCard(context, ref, notifications[index], isDarkMode, index);
                },
              ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, WidgetRef ref, NotificationModel notification, bool isDarkMode, int index) {
    IconData icon;
    Color iconColor;
    
    switch (notification.type) {
      case AppNotificationType.insight:
        icon = Icons.psychology_rounded;
        iconColor = AppColors.primaryAccent;
        break;
      case AppNotificationType.achievement:
        icon = Icons.emoji_events_rounded;
        iconColor = AppColors.secondaryAccent;
        break;
      case AppNotificationType.reminder:
        icon = Icons.notifications_active_rounded;
        iconColor = AppColors.highlight;
        break;
      case AppNotificationType.security:
        icon = Icons.security_rounded;
        iconColor = AppColors.negative;
        break;
    }

    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          ref.read(notificationProvider.notifier).markAsRead(notification.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.cardBg : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notification.isRead 
                ? (isDarkMode ? AppColors.glassBorder : AppColors.glassBorderDark)
                : AppColors.primaryAccent.withOpacity(0.5),
            width: notification.isRead ? 1 : 1.5,
          ),
          boxShadow: isDarkMode ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                        fontSize: 15,
                        color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
                      ),
                    ),
                  ),
                  Text(
                    _formatTimestamp(notification.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
                  ),
                ),
              ),
            ),
            if (!notification.isRead)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, 
            size: 80, color: isDarkMode ? Colors.white10 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.textPrimary : AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll notify you when you have new behavioral insights.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? AppColors.textSecondary : AppColors.textSecondaryDark,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }
}
