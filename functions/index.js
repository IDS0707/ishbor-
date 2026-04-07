/**
 * Ishbor — Firebase Cloud Functions
 *
 * Trigger: New message written to chats/{chatId}/messages/{messageId}
 * Action:  Send a push notification to the recipient's device via FCM.
 *
 * Deploy:
 *   npm install           (inside functions/)
 *   cd ..
 *   firebase deploy --only functions
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp }     = require('firebase-admin/app');
const { getFirestore }      = require('firebase-admin/firestore');
const { getMessaging }      = require('firebase-admin/messaging');

initializeApp();

const db  = getFirestore();
const fcm = getMessaging();

/**
 * Sends a push notification when a new chat message is created.
 *
 * Chat document path:  chats/{jobId}_{seekerUid}
 * Message sub-doc:     chats/{chatId}/messages/{messageId}
 *
 * Chat document fields: jobId, jobTitle, posterUid, seekerUid, seekerName
 * Message fields:       text, senderUid, createdAt
 * User document fields: fcmToken (saved by NotificationService.saveToken)
 */
exports.onNewChatMessage = onDocumentCreated(
  'chats/{chatId}/messages/{messageId}',
  async (event) => {
    const snap    = event.data;
    const chatId  = event.params.chatId;

    if (!snap) return;

    const msgData  = snap.data();
    const text      = msgData.text     ?? '';
    const senderUid = msgData.senderUid ?? '';

    if (!senderUid) return;

    // Load parent chat document to get participant UIDs + job info
    const chatSnap = await db.collection('chats').doc(chatId).get();
    if (!chatSnap.exists) return;

    const chat       = chatSnap.data();
    const jobId      = chat.jobId      ?? '';
    const jobTitle   = chat.jobTitle   ?? 'Yangi xabar';
    const posterUid  = chat.posterUid  ?? '';
    const seekerUid  = chat.seekerUid  ?? '';
    const seekerName = chat.seekerName ?? 'Ish izlovchi';

    // Determine recipient (the user who did NOT send the message)
    const recipientUid = senderUid === seekerUid ? posterUid : seekerUid;
    if (!recipientUid) return;

    // Get recipient's FCM token
    const userSnap = await db.collection('users').doc(recipientUid).get();
    if (!userSnap.exists) return;

    const userData  = userSnap.data();
    const fcmToken  = userData.fcmToken ?? '';
    if (!fcmToken) return;

    // Build notification
    const senderName  = senderUid === seekerUid ? seekerName : 'Ish beruvchi';
    const preview     = text.length > 100 ? text.substring(0, 100) + '…' : text;

    const message = {
      token: fcmToken,
      notification: {
        title: jobTitle,
        body:  `${senderName}: ${preview}`,
      },
      data: {
        // Payload used by the Flutter app to navigate to the correct ChatScreen
        jobId:        jobId,
        seekerUid:    seekerUid,
        posterUid:    posterUid,
        jobTitle:     jobTitle,
        opponentName: senderName,
        type:         'message',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'ishbor_messages',
          priority: 'high',
          defaultSound: true,
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    try {
      await fcm.send(message);
    } catch (err) {
      // Token might be stale — remove it so we don't spam errors
      if (
        err.code === 'messaging/registration-token-not-registered' ||
        err.code === 'messaging/invalid-registration-token'
      ) {
        await db
          .collection('users')
          .doc(recipientUid)
          .update({ fcmToken: require('firebase-admin/firestore').FieldValue.delete() });
      }
      console.error('FCM send error:', err.message);
    }
  }
);
