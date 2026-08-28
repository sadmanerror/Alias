import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, video, audio, gif, file }

class MessageModel extends Equatable {
  final String messageId;
  final String senderId;
  final String receiverId;
  final MessageType type;
  final String? content;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? fileName;
  final int? fileSize;
  final int? duration;
  final DateTime timestamp;
  final bool isRead;
  final bool isDelivered;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? gifUrl;
  final List<double>? waveformData;

  const MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.type,
    this.content,
    this.mediaUrl,
    this.thumbnailUrl,
    this.fileName,
    this.fileSize,
    this.duration,
    required this.timestamp,
    required this.isRead,
    required this.isDelivered,
    this.deliveredAt,
    this.readAt,
    this.gifUrl,
    this.waveformData,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return MessageModel(
      messageId: data['messageId'] as String? ?? doc.id,
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (data['type'] as String?),
        orElse: () => MessageType.text,
      ),
      content: data['content'] as String?,
      mediaUrl: data['mediaUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      fileName: data['fileName'] as String?,
      fileSize: data['fileSize'] as int?,
      duration: data['duration'] as int?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      isDelivered: data['isDelivered'] as bool? ?? false,
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      gifUrl: data['gifUrl'] as String?,
      waveformData: (data['waveformData'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  factory MessageModel.fromMap(Map<String, dynamic> data, [String? id]) {
    return MessageModel(
      messageId: data['messageId'] as String? ?? id ?? '',
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == (data['type'] as String?),
        orElse: () => MessageType.text,
      ),
      content: data['content'] as String?,
      mediaUrl: data['mediaUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      fileName: data['fileName'] as String?,
      fileSize: data['fileSize'] as int?,
      duration: data['duration'] as int?,
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : (data['timestamp'] is int
              ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int)
              : (data['timestamp'] is String
                  ? DateTime.tryParse(data['timestamp']) ?? DateTime.now()
                  : DateTime.now())),
      isRead: data['isRead'] as bool? ?? false,
      isDelivered: data['isDelivered'] as bool? ?? false,
      deliveredAt: data['deliveredAt'] is Timestamp
          ? (data['deliveredAt'] as Timestamp).toDate()
          : (data['deliveredAt'] is String
              ? DateTime.tryParse(data['deliveredAt'])
              : null),
      readAt: data['readAt'] is Timestamp
          ? (data['readAt'] as Timestamp).toDate()
          : (data['readAt'] is String
              ? DateTime.tryParse(data['readAt'])
              : null),
      gifUrl: data['gifUrl'] as String?,
      waveformData: (data['waveformData'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'type': typeString,
      'content': content,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'duration': duration,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'isDelivered': isDelivered,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'gifUrl': gifUrl,
      'waveformData': waveformData,
    };
  }

  Map<String, dynamic> toMap() => toFirestore();

  String get id => messageId;
  DateTime get createdAt => timestamp;

  MessageModel copyWith({
    String? messageId,
    String? senderId,
    String? receiverId,
    MessageType? type,
    String? content,
    String? mediaUrl,
    String? thumbnailUrl,
    String? fileName,
    int? fileSize,
    int? duration,
    DateTime? timestamp,
    bool? isRead,
    bool? isDelivered,
    DateTime? deliveredAt,
    DateTime? readAt,
    String? gifUrl,
    List<double>? waveformData,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      gifUrl: gifUrl ?? this.gifUrl,
      waveformData: waveformData ?? this.waveformData,
    );
  }

  bool get isMedia => type == MessageType.image || type == MessageType.video;
  bool get isAudio => type == MessageType.audio;
  String get typeString => type.name;

  @override
  List<Object?> get props => [
        messageId,
        senderId,
        receiverId,
        type,
        content,
        mediaUrl,
        thumbnailUrl,
        fileName,
        fileSize,
        duration,
        timestamp,
        isRead,
        isDelivered,
        deliveredAt,
        readAt,
        gifUrl,
        waveformData,
      ];
}
