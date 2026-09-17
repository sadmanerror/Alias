import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alias/models/message_model.dart'; // To resolve MessageType

class ChatModel extends Equatable {
  final String chatId;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final MessageType? lastMessageType;
  final String? lastMessageSenderId;
  final int unreadCount;

  // Group chat fields
  final bool isGroup;
  final String? groupName;
  final String? groupPhotoUrl;
  final String? adminId;

  // Custom user settings per chat
  final Map<String, String>? nicknames;
  final List<String>? mutedBy;

  const ChatModel({
    required this.chatId,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageType,
    this.lastMessageSenderId,
    required this.unreadCount,
    this.isGroup = false,
    this.groupName,
    this.groupPhotoUrl,
    this.adminId,
    this.nicknames,
    this.mutedBy,
  });

  /// Whether this chat is a 1-on-1 DM
  bool get isDM => !isGroup && participants.length == 2;

  bool isMutedFor(String uid) => mutedBy?.contains(uid) ?? false;
  String? getNicknameFor(String uid) => nicknames?[uid];

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    MessageType? msgType;
    if (data['lastMessageType'] != null) {
      msgType = MessageType.values.firstWhere(
        (e) => e.name == data['lastMessageType'],
        orElse: () => MessageType.text,
      );
    }

    return ChatModel(
      chatId: data['chatId'] as String? ?? doc.id,
      participants: (data['participants'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lastMessage: data['lastMessage'] as String?,
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      lastMessageType: msgType,
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      unreadCount: data['unreadCount'] as int? ?? 0,
      isGroup: data['isGroup'] as bool? ?? false,
      groupName: data['groupName'] as String?,
      groupPhotoUrl: data['groupPhotoUrl'] as String?,
      adminId: data['adminId'] as String?,
      nicknames: (data['nicknames'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as String),
      ),
      mutedBy: (data['mutedBy'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  factory ChatModel.fromMap(Map<String, dynamic> data, [String? id]) {
    MessageType? msgType;
    if (data['lastMessageType'] != null) {
      msgType = MessageType.values.firstWhere(
        (e) => e.name == data['lastMessageType'],
        orElse: () => MessageType.text,
      );
    }

    return ChatModel(
      chatId: data['chatId'] as String? ?? id ?? '',
      participants: (data['participants'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lastMessage: data['lastMessage'] as String?,
      lastMessageTime: data['lastMessageTime'] is Timestamp
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageType: msgType,
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      unreadCount: data['unreadCount'] as int? ?? 0,
      isGroup: data['isGroup'] as bool? ?? false,
      groupName: data['groupName'] as String?,
      groupPhotoUrl: data['groupPhotoUrl'] as String?,
      adminId: data['adminId'] as String?,
      nicknames: (data['nicknames'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as String),
      ),
      mutedBy: (data['mutedBy'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime':
          lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'lastMessageType': lastMessageType?.name,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'isGroup': isGroup,
      'groupName': groupName,
      'groupPhotoUrl': groupPhotoUrl,
      'adminId': adminId,
      if (nicknames != null) 'nicknames': nicknames,
      if (mutedBy != null) 'mutedBy': mutedBy,
    };
  }

  Map<String, dynamic> toMap() => toFirestore();

  String get id => chatId;
  DateTime? get lastUpdated => lastMessageTime;

  ChatModel copyWith({
    String? chatId,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    MessageType? lastMessageType,
    String? lastMessageSenderId,
    int? unreadCount,
    bool? isGroup,
    String? groupName,
    String? groupPhotoUrl,
    String? adminId,
    Map<String, String>? nicknames,
    List<String>? mutedBy,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      isGroup: isGroup ?? this.isGroup,
      groupName: groupName ?? this.groupName,
      groupPhotoUrl: groupPhotoUrl ?? this.groupPhotoUrl,
      adminId: adminId ?? this.adminId,
      nicknames: nicknames ?? this.nicknames,
      mutedBy: mutedBy ?? this.mutedBy,
    );
  }

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Display name for this chat (group name or partner nickname / username fallback)
  String displayName(String partnerUsername, [String? partnerUid]) {
    if (isGroup) return groupName ?? 'Group';
    if (partnerUid != null &&
        nicknames?[partnerUid] != null &&
        nicknames![partnerUid]!.trim().isNotEmpty) {
      return nicknames![partnerUid]!.trim();
    }
    return partnerUsername;
  }

  @override
  List<Object?> get props => [
        chatId,
        participants,
        lastMessage,
        lastMessageTime,
        lastMessageType,
        lastMessageSenderId,
        unreadCount,
        isGroup,
        groupName,
        groupPhotoUrl,
        adminId,
        nicknames,
        mutedBy,
      ];
}
