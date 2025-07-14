/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

exports.helloWorld = functions.https.onRequest((request, response) => {
  response.send("Hello from Firebase!");
});

exports.sendMessageNotification = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const message = snap.data();
    const chatId = context.params.chatId;
    const senderId = message.senderId;
    const text = message.text;

    // Get chat document to find participants
    const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();
    const participants = chatDoc.data().participants;
    // Find recipient (other than sender)
    const recipientId = participants.find(id => id !== senderId);
    if (!recipientId) return null;

    // Fetch recipient's FCM token
    const userDoc = await admin.firestore().collection('users').doc(recipientId).get();
    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return null;

    // Fetch sender's name
    const senderDoc = await admin.firestore().collection('users').doc(senderId).get();
    const senderName = senderDoc.data().fullName || 'New Message';

    // Send push notification
    const payload = {
      notification: {
        title: senderName,
        body: text,
      },
      data: {
        type: 'chat',
        chatId: chatId,
      },
    };
    await admin.messaging().sendToDevice(fcmToken, payload);
    return null;
  });
