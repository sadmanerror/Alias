import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alias/services/notification_helper_stub.dart'
    if (dart.library.html) 'package:alias/services/notification_helper_web.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String _channelCallsId = 'alias_calls_channel';
  static const String _channelMessagesId = 'alias_messages_channel';
  static const int callNotificationId = 9991;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );

      // Create Android Notification Channels
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelCallsId,
            'Incoming Calls',
            description: 'High-priority alerts for incoming calls',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelMessagesId,
            'Chat Messages',
            description: 'Notifications for new chat messages',
            importance: Importance.high,
            playSound: true,
          ),
        );
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  /// Check and prompt the user for notification permissions on initial app launch.
  Future<void> promptPermissionIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasPrompted = prefs.getBool('has_prompted_notifications') ?? false;
    if (hasPrompted) return;

    if (!context.mounted) return;

    // Show stylish in-app permission sheet before triggering system dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF0E8D8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4C8B2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF8DA399).withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFF2C3E35),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Stay Connected',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C3E35),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Allow notifications to receive immediate alerts for incoming voice calls and messages from your friends.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7264),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        prefs.setBool('has_prompted_notifications', true);
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Not Now',
                        style: TextStyle(
                          color: Color(0xFF8A9080),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8DA399),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        prefs.setBool('has_prompted_notifications', true);
                        Navigator.pop(ctx);
                        await requestPermissions();
                      },
                      child: const Text(
                        'Enable Notifications',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Triggers system notification permission requests across platforms.
  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb) {
        requestWebNotificationPermission();
        try {
          final settings = await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          return settings.authorizationStatus == AuthorizationStatus.authorized;
        } catch (_) {
          return true;
        }
      } else {
        // Mobile platform permissions
        final status = await Permission.notification.request();
        try {
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
        } catch (_) {}

        final androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.requestNotificationsPermission();
        }

        return status.isGranted;
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Show a phone notification for an incoming call.
  Future<void> showCallNotification({
    required String callerName,
    required String callId,
    required bool isVideo,
  }) async {
    final title = 'Incoming ${isVideo ? "Video" : "Audio"} Call';
    final body = '$callerName is calling you...';

    // 1. Web Notification
    if (kIsWeb) {
      showWebNotification(title, body, tag: 'call_$callId');
      return;
    }

    // 2. Native Mobile Notification
    const androidDetails = AndroidNotificationDetails(
      _channelCallsId,
      'Incoming Calls',
      channelDescription: 'Incoming call notification',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      ongoing: true,
      autoCancel: false,
      color: Color(0xFF8DA399),
      ledColor: Color(0xFF8DA399),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBanner: true,
      sound: 'default',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _localNotifications.show(
        callNotificationId,
        title,
        body,
        details,
        payload: 'call:$callId',
      );
    } catch (e) {
      debugPrint('Error showing call notification: $e');
    }
  }

  /// Dismiss the ringing call notification.
  Future<void> cancelCallNotification() async {
    try {
      await _localNotifications.cancel(callNotificationId);
    } catch (_) {}
  }

  /// Show a phone notification for a new message.
  Future<void> showMessageNotification({
    required String senderName,
    required String messageText,
    required String chatId,
  }) async {
    // 1. Web Notification
    if (kIsWeb) {
      showWebNotification(senderName, messageText, tag: 'chat_$chatId');
      return;
    }

    // 2. Native Mobile Notification
    final androidDetails = AndroidNotificationDetails(
      _channelMessagesId,
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      groupKey: chatId,
      color: const Color(0xFF8DA399),
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _localNotifications.show(
        chatId.hashCode ^ messageText.hashCode,
        senderName,
        messageText,
        details,
        payload: 'chat:$chatId',
      );
    } catch (e) {
      debugPrint('Error showing message notification: $e');
    }
  }
}
