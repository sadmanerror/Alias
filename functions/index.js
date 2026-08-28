const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { RtcTokenBuilder, RtcRole } = require('agora-access-token');

admin.initializeApp();
const db = admin.firestore();

// 1. onNewMessage (Firestore trigger)
exports.onNewMessage = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const newMessage = snap.data();
    const chatId = context.params.chatId;
    const senderId = newMessage.senderId;

    try {
      const chatDoc = await db.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) return null;

      const participants = chatDoc.data().participants || [];
      const recipientId = participants.find((id) => id !== senderId);

      if (!recipientId) return null;

      const recipientDoc = await db.collection('users').doc(recipientId).get();
      const senderDoc = await db.collection('users').doc(senderId).get();

      if (!recipientDoc.exists || !senderDoc.exists) return null;

      const recipientToken = recipientDoc.data().fcmToken;
      const senderUsername = senderDoc.data().username || 'Someone';

      if (!recipientToken) return null;

      let messagePreview = 'New message';
      if (newMessage.type === 'text') {
        messagePreview = newMessage.content.substring(0, 100);
      } else if (newMessage.type === 'image') {
        messagePreview = 'Sent an image';
      } else if (newMessage.type === 'audio') {
        messagePreview = 'Sent an audio message';
      } else if (newMessage.type === 'video') {
         messagePreview = 'Sent a video';
      }

      const payload = {
        notification: {
          title: senderUsername,
          body: messagePreview,
        },
        data: {
          chatId: chatId,
          type: 'new_message',
          senderId: senderId,
        },
        android: {
          notification: {
            channelId: 'messages',
            tag: chatId,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      };

      try {
        await admin.messaging().send({
          token: recipientToken,
          ...payload
        });
      } catch (error) {
        console.error('Error sending message:', error);
        if (
          error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered'
        ) {
          await recipientDoc.ref.update({ fcmToken: admin.firestore.FieldValue.delete() });
        }
      }
    } catch (error) {
      console.error('Error in onNewMessage:', error);
    }
  });

// 2. generateAgoraToken (HTTPS Callable)
exports.generateAgoraToken = functions.https.onCall((data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const channelName = data.channelName;
  const uid = data.uid || 0;
  const roleStr = data.role || 'publisher';

  if (!channelName) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'The function must be called with one argument "channelName" containing the channel name to generate a token for.'
    );
  }

  const appID = process.env.AGORA_APP_ID || functions.config().agora?.app_id;
  const appCertificate = process.env.AGORA_APP_CERTIFICATE || functions.config().agora?.certificate;
  
  if (!appID || !appCertificate) {
      throw new functions.https.HttpsError('failed-precondition', 'Agora app ID and certificate must be configured in environment variables.');
  }

  const expirationTimeInSeconds = 3600;
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

  const role = roleStr === 'publisher' ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

  const token = RtcTokenBuilder.buildTokenWithUid(
    appID,
    appCertificate,
    channelName,
    uid,
    role,
    privilegeExpiredTs
  );

  return { token };
});

// 3. onCallStatusChange (Firestore trigger)
exports.onCallStatusChange = functions.firestore
  .document('calls/{callId}')
  .onUpdate(async (change, context) => {
    const newValue = change.after.data();
    const previousValue = change.before.data();
    const callId = context.params.callId;

    if (newValue.status === previousValue.status) return null;

    try {
      if (newValue.status === 'ringing') {
        const calleeDoc = await db.collection('users').doc(newValue.calleeId).get();
        const callerDoc = await db.collection('users').doc(newValue.callerId).get();
        
        if (!calleeDoc.exists || !callerDoc.exists) return null;

        const calleeToken = calleeDoc.data().fcmToken;
        const callerName = callerDoc.data().username || 'Someone';

        if (!calleeToken) return null;

        const payload = {
          data: {
            type: 'call_invite',
            callId: callId,
            callerId: newValue.callerId,
            callerName: callerName,
            channelName: newValue.channelName,
            callType: newValue.type || 'video',
            token: newValue.token || ''
          }
        };

        try {
            await admin.messaging().send({
                token: calleeToken,
                ...payload
            });
        } catch(e) {
            console.log('Error sending call invite', e);
        }

      } else if (newValue.status === 'ended' || newValue.status === 'declined' || newValue.status === 'missed') {
         const calleeDoc = await db.collection('users').doc(newValue.calleeId).get();
         const callerDoc = await db.collection('users').doc(newValue.callerId).get();

         const tokens = [];
         if (calleeDoc.exists && calleeDoc.data().fcmToken) tokens.push(calleeDoc.data().fcmToken);
         if (callerDoc.exists && callerDoc.data().fcmToken) tokens.push(callerDoc.data().fcmToken);

         if (tokens.length > 0) {
            const payload = {
                data: {
                    type: 'call_ended',
                    callId: callId
                }
            };
            try {
               await admin.messaging().sendEachForMulticast({
                   tokens: tokens,
                   ...payload
               });
            } catch(e) {
                console.log('Error sending call ended', e);
            }
         }
      }
    } catch (error) {
      console.error('Error in onCallStatusChange:', error);
    }
  });

// 4. cleanupOldCalls (Scheduled function)
exports.cleanupOldCalls = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
  const twentyFourHoursAgo = admin.firestore.Timestamp.fromMillis(Date.now() - 24 * 60 * 60 * 1000);
  
  try {
    const querySnapshot = await db.collection('calls')
      .where('createdAt', '<', twentyFourHoursAgo)
      .where('status', 'in', ['ended', 'declined', 'missed'])
      .get();
      
    if (querySnapshot.empty) return null;

    const batch = db.batch();
    querySnapshot.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Deleted ${querySnapshot.size} old calls.`);
  } catch (error) {
    console.error('Error cleaning up old calls:', error);
  }
  return null;
});
