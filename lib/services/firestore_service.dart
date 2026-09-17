import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alias/models/chat_model.dart';
import 'package:alias/models/message_model.dart';
import 'package:alias/models/user_model.dart';
import 'package:alias/models/call_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  // ─────────────────────────────────────────────────────────────────────────
  // DM Chat
  // ─────────────────────────────────────────────────────────────────────────

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
        'isGroup': false,
        'unreadCount': 0,
      });
    }
    return chatId;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Group Chat
  // ─────────────────────────────────────────────────────────────────────────

  /// Creates a new group chat and returns its chatId.
  Future<String> createGroupChat({
    required String adminId,
    required String groupName,
    required List<String> memberIds, // should include adminId
    String? groupPhotoUrl,
  }) async {
    final allMembers = ({adminId, ...memberIds}).toList();
    final docRef = _firestore.collection('chats').doc();
    final chatId = docRef.id;

    await docRef.set({
      'chatId': chatId,
      'participants': allMembers,
      'lastMessage': null,
      'lastMessageTime': null,
      'lastMessageType': null,
      'isGroup': true,
      'groupName': groupName.trim(),
      'groupPhotoUrl': groupPhotoUrl,
      'adminId': adminId,
      'unreadCount': 0,
    });

    return chatId;
  }

  /// Add a new member to an existing group chat.
  Future<void> addMemberToGroup(String chatId, String newMemberId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayUnion([newMemberId]),
    });
  }

  /// Remove a member from a group chat.
  Future<void> removeMemberFromGroup(String chatId, String memberId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'participants': FieldValue.arrayRemove([memberId]),
    });
  }

  /// Update group name / photo.
  Future<void> updateGroupInfo(
    String chatId, {
    String? groupName,
    String? groupPhotoUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (groupName != null) updates['groupName'] = groupName.trim();
    if (groupPhotoUrl != null) updates['groupPhotoUrl'] = groupPhotoUrl;
    if (updates.isNotEmpty) {
      await _firestore.collection('chats').doc(chatId).update(updates);
    }
  }

  /// Stream a single chat model in real-time
  Stream<ChatModel?> streamChat(String chatId) {
    return _firestore.collection('chats').doc(chatId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ChatModel.fromMap(doc.data()!, doc.id);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared Chat helpers
  // ─────────────────────────────────────────────────────────────────────────

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
      'lastMessage': msg.content ??
          (msg.type == MessageType.image
              ? '📷 Image'
              : (msg.type == MessageType.audio
                  ? '🎤 Voice message'
                  : (msg.type == MessageType.video
                      ? '🎬 Video'
                      : (msg.type == MessageType.gif ? 'GIF' : 'Media')))),
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
          if (doc.data()['deliveredAt'] == null)
            'deliveredAt': Timestamp.fromDate(now),
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

  Future<void> markMessagesAsDelivered(
      String chatId, String currentUserId) async {
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

  // ─────────────────────────────────────────────────────────────────────────
  // Messages
  // ─────────────────────────────────────────────────────────────────────────

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MessageModel.fromMap(doc.data())).toList());
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

  // ─────────────────────────────────────────────────────────────────────────
  // Users
  // ─────────────────────────────────────────────────────────────────────────

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final clean = username.trim();
    if (clean.isEmpty) return null;

    // 1. Try exact match
    var query = await _firestore
        .collection('users')
        .where('username', isEqualTo: clean)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return UserModel.fromMap(query.docs.first.data());
    }

    // 2. Try lowercased
    if (clean.toLowerCase() != clean) {
      query = await _firestore
          .collection('users')
          .where('username', isEqualTo: clean.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return UserModel.fromMap(query.docs.first.data());
      }
    }

    // 3. Try capitalized
    final capitalized = clean[0].toUpperCase() + clean.substring(1).toLowerCase();
    if (capitalized != clean) {
      query = await _firestore
          .collection('users')
          .where('username', isEqualTo: capitalized)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return UserModel.fromMap(query.docs.first.data());
      }
    }

    return null;
  }

  /// Search users whose username starts with [prefix] (case-insensitive).
  /// Returns up to [limit] results, excluding [excludeUid].
  Future<List<UserModel>> searchUsersByPrefix(
    String prefix, {
    String? excludeUid,
    int limit = 10,
  }) async {
    if (prefix.trim().isEmpty) return [];
    final lower = prefix.toLowerCase().trim();
    final upper = lower.substring(0, lower.length - 1) +
        String.fromCharCode(lower.codeUnitAt(lower.length - 1) + 1);

    final query = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: lower)
        .where('username', isLessThan: upper)
        .limit(limit + 1)
        .get();

    return query.docs
        .map((d) => UserModel.fromMap(d.data()))
        .where((u) => u.uid != excludeUid)
        .take(limit)
        .toList();
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

  // ─────────────────────────────────────────────────────────────────────────
  // Calls
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> initiateCall(CallModel call) async {
    final docRef = _firestore
        .collection('calls')
        .doc(call.callId.isNotEmpty ? call.callId : null);
    final callToSave = call.copyWith(callId: docRef.id);
    await docRef.set(callToSave.toFirestore());
    return docRef.id;
  }

  Future<void> updateCallStatus(String callId, String status) async {
    if (callId.trim().isEmpty) return;
    try {
      final docRef = _firestore.collection('calls').doc(callId);
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        await docRef.update({
          'status': status,
          if (status == 'ended' || status == 'declined' || status == 'missed')
            'endedAt': FieldValue.serverTimestamp(),
        });
        return;
      }
    } catch (e) {
      debugPrint('updateCallStatus doc error: $e');
    }

    // Fallback: search by 'callId' field if doc(callId) was not matched
    try {
      final query = await _firestore
          .collection('calls')
          .where('callId', isEqualTo: callId)
          .get();
      for (final doc in query.docs) {
        await doc.reference.update({
          'status': status,
          if (status == 'ended' || status == 'declined' || status == 'missed')
            'endedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('updateCallStatus fallback error: $e');
    }
  }

  Stream<CallModel?> streamIncomingCalls(String uid) {
    return _firestore
        .collection('calls')
        .where('calleeId', isEqualTo: uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final calls = snapshot.docs
          .map((doc) => CallModel.fromMap(doc.data(), doc.id))
          .toList();
      calls.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      final latest = calls.first;
      // Stale call check: if older than 2 minutes, auto-clean and ignore
      if (DateTime.now().difference(latest.startedAt).inMinutes > 2) {
        for (final stale in calls) {
          updateCallStatus(stale.callId, 'missed');
        }
        return null;
      }
      return latest;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DM Settings Helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// Update or clear a custom nickname for a user in a chat
  Future<void> updateChatNickname(
    String chatId,
    String partnerUid,
    String nickname,
  ) async {
    final clean = nickname.trim();
    if (clean.isEmpty) {
      await _firestore.collection('chats').doc(chatId).update({
        'nicknames.$partnerUid': FieldValue.delete(),
      });
    } else {
      await _firestore.collection('chats').doc(chatId).update({
        'nicknames.$partnerUid': clean,
      });
    }
  }

  /// Toggle mute status of a chat for a specific user
  Future<void> toggleMuteChat(
    String chatId,
    String uid,
    bool isMuted,
  ) async {
    await _firestore.collection('chats').doc(chatId).update({
      'mutedBy': isMuted
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }

  /// Clear all messages in a chat and reset lastMessage
  Future<void> clearChatHistory(String chatId) async {
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.update(_firestore.collection('chats').doc(chatId), {
      'lastMessage': null,
      'lastMessageTime': null,
      'lastMessageType': null,
      'lastMessageSenderId': null,
      'unreadCount': 0,
    });
    await batch.commit();
  }
}

