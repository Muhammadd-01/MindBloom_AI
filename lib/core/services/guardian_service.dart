import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'local_ai_engine.dart';

/// GuardianService runs in the background on Android to monitor incoming chats
/// and detect signs of distress, anger, or suicidal ideation.
class GuardianService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;

  /// Initialize local notifications for sending help alerts
  static Future<void> init() async {
    if (_isInitialized) return;

    // Request Notification Permission
    await _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // For iOS, though Guardian Mode is Android only, we setup dummy settings
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(settings: initializationSettings);
    _isInitialized = true;
  }

  /// Request Android Notification Listener Permission
  static Future<bool> requestPermission() async {
    final bool status = await NotificationListenerService.isPermissionGranted();
    if (!status) {
      await NotificationListenerService.requestPermission();
      return await NotificationListenerService.isPermissionGranted();
    }
    return true;
  }

  /// Start the background listener for incoming chats (WhatsApp, Messenger, SMS, etc.)
  static Future<void> startListening() async {
    try {
      final hasPermission = await NotificationListenerService.isPermissionGranted();
      if (!hasPermission) {
        if (kDebugMode) print('Guardian Mode: Permission not granted.');
        return;
      }

      if (kDebugMode) print('🛡️ Guardian Mode: Active and listening for distress signals...');

      // Listen to incoming notifications
      NotificationListenerService.notificationsStream.listen((ServiceNotificationEvent event) async {
        if (event.content == null || event.content!.isEmpty) return;

        // Ignore our own app notifications
        if (event.packageName == 'com.example.mindbloom_ai' || event.packageName!.contains('mindbloom')) return;

        // Check if it's a messaging app (WhatsApp, Telegram, Messages)
        // For prototype, we analyze all incoming text
        final text = event.content!;
        
        await _analyzeAndRespond(text, event.packageName ?? 'Unknown App');
      });
    } catch (e) {
      if (kDebugMode) print('Guardian Mode Error: $e');
    }
  }

  static Future<void> _analyzeAndRespond(String text, String appName) async {
    final lower = text.toLowerCase();
    
    // 1. Extreme Crisis Detection (Suicide/Self-harm)
    if (MindBloomLocalAIEngine.isCrisis(lower)) {
      await _sendDistressAlert(
        title: 'Emergency Alert Detected',
        body: 'We noticed signs of extreme distress. You are not alone. Please tap here for emergency help.',
      );
      return;
    }

    // 2. High Anger / Rage Detection
    final angerWords = ['hate', 'angry', 'furious', 'rage', 'idiot', 'stupid', 'kill'];
    int angerCount = 0;
    for (var w in angerWords) {
      if (lower.contains(w)) angerCount++;
    }
    
    if (angerCount >= 2) {
      await _sendDistressAlert(
        title: 'Take a Breath',
        body: 'A heated conversation was detected on $appName. Take 3 deep breaths before responding.',
      );
      return;
    }

    // 3. Deep Sadness Detection
    final sadnessWords = ['depressed', 'crying', 'hopeless', 'empty', 'lonely', 'sad', 'give up'];
    int sadCount = 0;
    for (var w in sadnessWords) {
      if (lower.contains(w)) sadCount++;
    }

    if (sadCount >= 2) {
      await _sendDistressAlert(
        title: 'I\'m Here For You',
        body: 'It sounds like you\'re having a hard time. Open MindBloom whenever you need a safe space to vent.',
      );
    }
  }

  static Future<void> _sendDistressAlert({required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'guardian_channel',
      'MindBloom Guardian',
      channelDescription: 'Emergency and emotional support alerts',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      color: Color(0xFF10B981), // App green
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
        
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch % 100000, // Random ID
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: 'guardian_alert',
    );
  }
}
