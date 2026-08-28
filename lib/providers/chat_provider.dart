import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:alias/services/firestore_service.dart';
import 'package:alias/services/storage_service.dart';
import 'package:alias/models/chat_model.dart';
import 'package:alias/models/message_model.dart';
import 'package:alias/models/user_model.dart';
import 'package:alias/providers/auth_provider.dart';
import 'package:alias/services/giphy_service.dart';
import 'package:http/http.dart' as http;

part 'chat_provider.g.dart';

@riverpod
GiphyService giphyService(Ref ref) {
  return GiphyService(http.Client());
}

@riverpod
FirestoreService firestoreService(Ref ref) {
  return FirestoreService(FirebaseFirestore.instance);
}

@riverpod
StorageService storageService(Ref ref) {
  return StorageService(FirebaseStorage.instance);
}

@riverpod
Stream<List<ChatModel>> userChats(Ref ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(<ChatModel>[]);
  return ref.watch(firestoreServiceProvider).getUserChats(user.uid);
}

@riverpod
Stream<List<MessageModel>> chatMessages(Ref ref, String chatId) {
  return ref.watch(firestoreServiceProvider).getMessages(chatId);
}

@riverpod
class MessageNotifier extends _$MessageNotifier {
  @override
  FutureOr<void> build(String chatId) async {}

  String _getPartnerId(String currentUid) {
    final parts = chatId.split('_');
    if (parts.length == 2) {
      return parts[0] == currentUid ? parts[1] : parts[0];
    }
    return '';
  }

  Future<void> sendTextMessage(String content) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final partnerId = _getPartnerId(user.uid);
    final partnerProfile = partnerId.isNotEmpty
        ? ref.read(userProfileProvider(partnerId)).value
        : null;
    final isOnline = partnerProfile?.isOnline == true;
    final now = DateTime.now();

    final msg = MessageModel(
      messageId: '',
      senderId: user.uid,
      receiverId: partnerId,
      type: MessageType.text,
      content: content,
      timestamp: now,
      isRead: false,
      isDelivered: isOnline,
      deliveredAt: isOnline ? now : null,
    );
    await ref.read(firestoreServiceProvider).sendMessage(chatId, msg);
  }

  Future<void> sendMediaMessage(File file, MessageType type) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final partnerId = _getPartnerId(user.uid);
    final partnerProfile = partnerId.isNotEmpty
        ? ref.read(userProfileProvider(partnerId)).value
        : null;
    final isOnline = partnerProfile?.isOnline == true;
    final now = DateTime.now();

    final url = await ref.read(storageServiceProvider).uploadMedia(
          file: file,
          chatId: chatId,
          messageType: type.name,
        );
    final msg = MessageModel(
      messageId: '',
      senderId: user.uid,
      receiverId: partnerId,
      type: type,
      mediaUrl: url,
      timestamp: now,
      isRead: false,
      isDelivered: isOnline,
      deliveredAt: isOnline ? now : null,
    );
    await ref.read(firestoreServiceProvider).sendMessage(chatId, msg);
  }

  Future<void> sendVoiceMessage(File file, List<double> waveformData, int durationSeconds) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final partnerId = _getPartnerId(user.uid);
    final partnerProfile = partnerId.isNotEmpty
        ? ref.read(userProfileProvider(partnerId)).value
        : null;
    final isOnline = partnerProfile?.isOnline == true;
    final now = DateTime.now();

    final url = await ref.read(storageServiceProvider).uploadVoiceMessage(file, chatId);
    final msg = MessageModel(
      messageId: '',
      senderId: user.uid,
      receiverId: partnerId,
      type: MessageType.audio,
      mediaUrl: url,
      duration: durationSeconds,
      waveformData: waveformData,
      timestamp: now,
      isRead: false,
      isDelivered: isOnline,
      deliveredAt: isOnline ? now : null,
    );
    await ref.read(firestoreServiceProvider).sendMessage(chatId, msg);
  }

  Future<void> sendGif(GiphyGif gif) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final partnerId = _getPartnerId(user.uid);
    final partnerProfile = partnerId.isNotEmpty
        ? ref.read(userProfileProvider(partnerId)).value
        : null;
    final isOnline = partnerProfile?.isOnline == true;
    final now = DateTime.now();

    final msg = MessageModel(
      messageId: '',
      senderId: user.uid,
      receiverId: partnerId,
      type: MessageType.gif,
      gifUrl: gif.originalUrl,
      timestamp: now,
      isRead: false,
      isDelivered: isOnline,
      deliveredAt: isOnline ? now : null,
    );
    await ref.read(firestoreServiceProvider).sendMessage(chatId, msg);
  }

  Future<void> markAsRead() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    await ref.read(firestoreServiceProvider).markMessagesAsRead(chatId, user.uid);
  }

  Future<void> markAsDelivered() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    await ref.read(firestoreServiceProvider).markMessagesAsDelivered(chatId, user.uid);
  }
}

@riverpod
Stream<UserModel?> userProfile(Ref ref, String uid) {
  if (uid.isEmpty) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).streamUser(uid);
}

@riverpod
Future<UserModel?> chatPartner(Ref ref, String chatId) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  try {
    final chats = await ref.watch(firestoreServiceProvider).getUserChats(user.uid).first;
    final chat = chats.where((c) => c.chatId == chatId).firstOrNull;
    if (chat == null) return null;
    final partnerId = chat.getOtherParticipantId(user.uid);
    if (partnerId.isEmpty) return null;
    return await ref.watch(firestoreServiceProvider).getUserById(partnerId);
  } catch (e) {
    return null;
  }
}

final messageNotifierProvider = messageProvider;

