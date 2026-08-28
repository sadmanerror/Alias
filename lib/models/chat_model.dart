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

  const ChatModel({
    required this.chatId,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageType,
    this.lastMessageSenderId,
    required this.unreadCount,
  });

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
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
  
  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
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
      ];
}
