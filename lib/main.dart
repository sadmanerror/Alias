import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:alias/firebase_options.dart';
import 'package:alias/core/config/theme.dart';
import 'package:alias/core/router/app_router.dart';
import 'package:alias/services/presence_service.dart';
import 'package:alias/services/notification_service.dart';
import 'package:alias/models/call_model.dart';
import 'package:alias/models/chat_model.dart';
import 'package:alias/providers/auth_provider.dart';
import 'package:alias/providers/call_provider.dart';
import 'package:alias/providers/chat_provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Handle background message
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }

  // Initialize notifications service (cross-platform & Web)
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Error initializing NotificationService: $e');
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize presence service for online/offline tracking
  final presenceService = PresenceService();
  presenceService.initialize();

  runApp(
    const ProviderScope(
      child: AliasApp(),
    ),
  );
}

class AliasApp extends ConsumerWidget {
  const AliasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Alias',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) => RootNotificationHandler(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

class RootNotificationHandler extends ConsumerStatefulWidget {
  final Widget child;
  const RootNotificationHandler({super.key, required this.child});

  @override
  ConsumerState<RootNotificationHandler> createState() =>
      _RootNotificationHandlerState();
}

class _RootNotificationHandlerState
    extends ConsumerState<RootNotificationHandler> {
  final Map<String, DateTime> _lastNotifiedTime = {};
  final Map<String, String> _userNamesCache = {};

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final currentUserId = currentUser?.uid ?? '';

    // Global incoming 1-on-1 call listener
    ref.listen<AsyncValue<CallModel?>>(incomingCallProvider, (previous, next) {
      final call = next.value;
      if (call != null &&
          call.status == CallStatus.ringing &&
          call.callerId != currentUserId) {
        NotificationService.instance.showCallNotification(
          callerName: call.callerName ?? 'Someone',
          callId: call.callId,
          isVideo: call.type == CallType.video,
        );
      } else {
        NotificationService.instance.cancelCallNotification();
      }
    });

    // Global incoming message listener
    ref.listen<AsyncValue<List<ChatModel>>>(userChatsProvider, (previous, next) {
      if (next.hasValue && next.value != null && currentUserId.isNotEmpty) {
        for (final chat in next.value!) {
          if (chat.isMutedFor(currentUserId)) continue;
          if (chat.lastMessage == null || chat.lastMessage!.isEmpty) continue;
          if (chat.lastMessageSenderId == null ||
              chat.lastMessageSenderId == currentUserId) {
            continue;
          }
          if (chat.unreadCount <= 0) continue;

          final msgTime = chat.lastMessageTime;
          if (msgTime == null) continue;

          // Deduplicate notifications
          final lastNotified = _lastNotifiedTime[chat.chatId];
          if (lastNotified != null && !msgTime.isAfter(lastNotified)) continue;
          _lastNotifiedTime[chat.chatId] = msgTime;

          _notifyNewMessage(chat, currentUserId);
        }
      }
    });

    return widget.child;
  }

  Future<void> _notifyNewMessage(ChatModel chat, String currentUserId) async {
    String senderName = '';
    final senderId = chat.lastMessageSenderId ?? '';

    if (chat.isGroup) {
      senderName = chat.groupName ?? 'Group Message';
    } else {
      final partnerId = chat.getOtherParticipantId(currentUserId);
      final nickname = chat.nicknames?[partnerId];
      if (nickname != null && nickname.trim().isNotEmpty) {
        senderName = nickname.trim();
      } else if (_userNamesCache.containsKey(senderId)) {
        senderName = _userNamesCache[senderId]!;
      } else {
        try {
          final user =
              await ref.read(firestoreServiceProvider).getUserById(senderId);
          if (user != null && user.username.isNotEmpty) {
            _userNamesCache[senderId] = user.username;
            senderName = user.username;
          }
        } catch (_) {}
      }
    }

    if (senderName.isEmpty) {
      senderName = 'New Message';
    }

    await NotificationService.instance.showMessageNotification(
      senderName: senderName,
      messageText: chat.lastMessage!,
      chatId: chat.chatId,
    );
  }
}
