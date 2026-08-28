import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alias/models/chat_model.dart';
import 'package:alias/models/message_model.dart';
import 'package:alias/models/user_model.dart';
import 'package:alias/models/call_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  Future<String> createOrGetChatId(String uid1, String uid2) async {
    final uids = [uid1, uid2]..sort();
    final chatId = uids.join('_');

    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      await _firestore.collection('chats').doc(chatId).set({
        'chatId': chatId,
        'participants': uids,
        'lastMessage': null,
        'lastMessageTime': null,
        'lastMessageType': null,
      });
    }
    return chatId;
  }

  Stream<List<ChatModel>> getUserChats(String uid) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data()))
              .toList();
          chats.sort((a, b) {
            if (a.lastMessageTime == null) return 1;
            if (b.lastMessageTime == null) return -1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!);
          });
          return chats;
        });
  }

  Future<void> updateLastMessage(String chatId, MessageModel msg) async {
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': msg.content ?? (msg.type == MessageType.image ? '📷 Image' : (msg.type == MessageType.audio ? '🎤 Voice message' : 'Media')),
      'lastMessageTime': Timestamp.fromDate(msg.timestamp),
      'lastMessageType': msg.type.name,
      'lastMessageSenderId': msg.senderId,
      'unreadCount': FieldValue.increment(1),
    });
  }

  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    final unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    final now = DateTime.now();
    bool hasUnreadFromOther = false;

    for (var doc in unreadMessages.docs) {
      if (doc.data()['senderId'] != currentUserId) {
        hasUnreadFromOther = true;
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': Timestamp.fromDate(now),
          'isDelivered': true,
          if (doc.data()['deliveredAt'] == null) 'deliveredAt': Timestamp.fromDate(now),
        });
      }
    }

    if (hasUnreadFromOther || unreadMessages.docs.isNotEmpty) {
      batch.update(_firestore.collection('chats').doc(chatId), {
        'unreadCount': 0,
      });
    }

    await batch.commit();
  }

  Future<void> markMessagesAsDelivered(String chatId, String currentUserId) async {
    final undeliveredMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isDelivered', isEqualTo: false)
        .get();

    if (undeliveredMessages.docs.isEmpty) return;

    final batch = _firestore.batch();
    final now = DateTime.now();
    for (var doc in undeliveredMessages.docs) {
      if (doc.data()['senderId'] != currentUserId) {
        batch.update(doc.reference, {
          'isDelivered': true,
          'deliveredAt': Timestamp.fromDate(now),
        });
      }
    }
    await batch.commit();
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  Future<String> sendMessage(String chatId, MessageModel message) async {
    final docRef = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toMap());
        
    await updateLastMessage(chatId, message);
    return docRef.id;
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username.toLowerCase().trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return UserModel.fromMap(query.docs.first.data());
  }

  Stream<UserModel?> streamUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!);
    });
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<String> initiateCall(CallModel call) async {
    final docRef = await _firestore.collection('calls').add(call.toFirestore());
    return docRef.id;
  }

  Future<void> updateCallStatus(String callId, String status) async {
    await _firestore.collection('calls').doc(callId).update({'status': status});
  }

  Stream<CallModel?> streamIncomingCalls(String uid) {
    return _firestore
        .collection('calls')
        .where('calleeId', isEqualTo: uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return CallModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
    });
  }
}
