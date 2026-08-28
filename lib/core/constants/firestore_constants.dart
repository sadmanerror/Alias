class FirestoreConstants {
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesSubcollection = 'messages';
  static const String callsCollection = 'calls';

  // User fields
  static const String uid = 'uid';
  static const String username = 'username';
  static const String email = 'email';
  static const String photoUrl = 'photoUrl';
  static const String fcmToken = 'fcmToken';
  static const String createdAt = 'createdAt';
  static const String lastSeen = 'lastSeen';
  static const String isOnline = 'isOnline';

  // Chat fields
  static const String participants = 'participants';
  static const String lastMessage = 'lastMessage';
  static const String lastMessageTime = 'lastMessageTime';
  static const String lastMessageType = 'lastMessageType';
  static const String lastMessageSenderId = 'lastMessageSenderId';

  // Message fields
  static const String messageId = 'messageId';
  static const String senderId = 'senderId';
  static const String receiverId = 'receiverId';
  static const String type = 'type';
  static const String content = 'content';
  static const String mediaUrl = 'mediaUrl';
  static const String thumbnailUrl = 'thumbnailUrl';
  static const String fileName = 'fileName';
  static const String fileSize = 'fileSize';
  static const String duration = 'duration';
  static const String timestamp = 'timestamp';
  static const String isRead = 'isRead';
  static const String isDelivered = 'isDelivered';
  static const String waveformData = 'waveformData';
  static const String gifUrl = 'gifUrl';

  // Call fields
  static const String callId = 'callId';
  static const String callerId = 'callerId';
  static const String calleeId = 'calleeId';
  static const String channelName = 'channelName';
  static const String status = 'status';
  static const String callType = 'type';
  static const String startedAt = 'startedAt';
  static const String endedAt = 'endedAt';

  // Message types
  static const String typeText = 'text';
  static const String typeImage = 'image';
  static const String typeVideo = 'video';
  static const String typeAudio = 'audio';
  static const String typeGif = 'gif';
  static const String typeFile = 'file';

  // Call statuses
  static const String statusRinging = 'ringing';
  static const String statusActive = 'active';
  static const String statusEnded = 'ended';
  static const String statusDeclined = 'declined';
  static const String statusMissed = 'missed';

  // Call types
  static const String typeCallAudio = 'audio';
  static const String typeCallVideo = 'video';
}
