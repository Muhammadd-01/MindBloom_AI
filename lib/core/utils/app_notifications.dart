import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../main.dart'; // To access snackbarKey

enum NotificationType { success, error, info, warning }

class AppNotifications {
  /// Show a premium styled notification. 
  /// If [context] is null, it uses the global [snackbarKey].
  static void show(
    BuildContext? context, {
    required String message,
    String? title,
    NotificationType type = NotificationType.info,
  }) {
    final messenger = context != null 
        ? ScaffoldMessenger.of(context) 
        : snackbarKey.currentState;
    
    if (messenger == null) return;
    
    messenger.clearSnackBars();
    
    final color = _getColor(type);
    final icon = _getIcon(type);

    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 4),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.95), // Deep slate for premium look
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: title != null ? 12 : 14,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                onPressed: () => messenger.hideCurrentSnackBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _getColor(NotificationType type) {
    switch (type) {
      case NotificationType.success: return const Color(0xFF10B981);
      case NotificationType.error: return const Color(0xFFEF4444);
      case NotificationType.warning: return const Color(0xFFF59E0B);
      case NotificationType.info: return AppColors.primaryAccent;
    }
  }

  static IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success: return Icons.check_circle_rounded;
      case NotificationType.error: return Icons.error_rounded;
      case NotificationType.warning: return Icons.warning_rounded;
      case NotificationType.info: return Icons.info_rounded;
    }
  }

  /// High-level helper to show errors with friendly messaging
  static void showError(BuildContext? context, dynamic error) {
    show(
      context,
      message: getFriendlyErrorMessage(error),
      type: NotificationType.error,
      title: 'Action Needed',
    );
  }

  /// Specialized error handler to avoid showing "Code Errors" to the user
  static String getFriendlyErrorMessage(dynamic error) {
    final eStr = error.toString().toLowerCase();
    
    if (eStr.contains('socketexception') || eStr.contains('network')) {
      return "MindBloom AI is taking a stroll offline. We'll use smart simulation until your connection returns.";
    }
    if (eStr.contains('user-not-found') || eStr.contains('no-account')) {
      return "We couldn't find an account with that email. Would you like to create one?";
    }
    if (eStr.contains('wrong-password') || eStr.contains('invalid-credential') || eStr.contains('firebaseauth')) {
      return "The password or email doesn't seem right. Please double-check and try again.";
    }
    if (eStr.contains('email-already-in-use')) {
      return "This email is already part of the MindBloom family. Try logging in instead.";
    }
    if (eStr.contains('weak-password')) {
      return "For your security, please use a stronger password (at least 6 characters).";
    }
    if (eStr.contains('permission-denied') || eStr.contains('permission')) {
      return "Secure Access: We're double-checking your permissions. Please ensure the app has the necessary access.";
    }
    if (eStr.contains('timeout')) {
      return "The network is a bit slow today. MindBloom AI is patiently waiting for a response.";
    }
    if (eStr.contains('too-many-requests')) {
      return "Slow down a bit! Too many attempts. Please wait a moment before trying again.";
    }
    
    return "Something unexpected happened, but don't worry—our AI is still looking out for you!";
  }
}
