import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
}

class FcmService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  FcmService(this._messaging, this._firestore, this._auth);

  Future<void> initialize() async {
    // Request permission for iOS
    await _messaging.requestPermission();

    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({'fcmToken': token});
      }
    }

    // Set up local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _localNotifications.initialize(initializationSettings);

    // Listen to messages
    FirebaseMessaging.onMessage.listen(showLocalNotification);
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Handle navigation
    });
  }

  void showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;
    
    if (notification != null) {
      final chatId = data['chatId'] ?? 'default_group';
      
      final androidDetails = AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'Notifications for new chat messages',
        importance: Importance.max,
        priority: Priority.high,
        groupKey: chatId,
      );
      
      const iosDetails = DarwinNotificationDetails();
      
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
      
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
      );
    }
  }

  Future<void> sendCallNotification({
    required String targetFcmToken,
    required String callerName,
    required String callId,
    required String channelName,
    required bool isVideo,
  }) async {
    // Sending is done server-side via Cloud Functions.
  }
}
