import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum CallStatus { ringing, active, ended, declined, missed }
enum CallType { audio, video }

class CallModel extends Equatable {
  final String callId;
  final String callerId;
  final String calleeId;
  final String channelName;
  final CallStatus status;
  final CallType type;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? agoraToken;

  const CallModel({
    required this.callId,
    required this.callerId,
    required this.calleeId,
    required this.channelName,
    required this.status,
    required this.type,
    required this.startedAt,
    this.endedAt,
    this.agoraToken,
  });

  factory CallModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return CallModel(
      callId: data['callId'] as String? ?? doc.id,
      callerId: data['callerId'] as String? ?? '',
      calleeId: data['calleeId'] as String? ?? '',
      channelName: data['channelName'] as String? ?? '',
      status: CallStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String?),
        orElse: () => CallStatus.ended,
      ),
      type: CallType.values.firstWhere(
        (e) => e.name == (data['type'] as String?),
        orElse: () => CallType.audio,
      ),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      agoraToken: data['agoraToken'] as String?,
    );
  }

  factory CallModel.fromJson(Map<String, dynamic> json, [String? id]) =>
      CallModel.fromMap(json, id ?? json['callId'] as String? ?? '');

  factory CallModel.fromMap(Map<String, dynamic> data, String id) {
    return CallModel(
      callId: data['callId'] as String? ?? id,
      callerId: data['callerId'] as String? ?? '',
      calleeId: data['calleeId'] as String? ?? '',
      channelName: data['channelName'] as String? ?? '',
      status: CallStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String?),
        orElse: () => CallStatus.ended,
      ),
      type: CallType.values.firstWhere(
        (e) => e.name == (data['type'] as String?),
        orElse: () => CallType.audio,
      ),
      startedAt: data['startedAt'] is Timestamp 
          ? (data['startedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      endedAt: data['endedAt'] is Timestamp 
          ? (data['endedAt'] as Timestamp).toDate() 
          : null,
      agoraToken: data['agoraToken'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'callId': callId,
      'callerId': callerId,
      'calleeId': calleeId,
      'channelName': channelName,
      'status': status.name,
      'type': type.name,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'agoraToken': agoraToken,
    };
  }

  Map<String, dynamic> toMap() => toFirestore();

  String get id => callId;
  DateTime get timestamp => startedAt;
  String get callerName => callerId;

  CallModel copyWith({
    String? callId,
    String? callerId,
    String? calleeId,
    String? channelName,
    CallStatus? status,
    CallType? type,
    DateTime? startedAt,
    DateTime? endedAt,
    String? agoraToken,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      calleeId: calleeId ?? this.calleeId,
      channelName: channelName ?? this.channelName,
      status: status ?? this.status,
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      agoraToken: agoraToken ?? this.agoraToken,
    );
  }

  Duration? get callDuration {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt);
  }

  @override
  List<Object?> get props => [
        callId,
        callerId,
        calleeId,
        channelName,
        status,
        type,
        startedAt,
        endedAt,
        agoraToken,
      ];
}
