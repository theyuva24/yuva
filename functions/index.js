/**
 * Import function triggers from their respective submodules:
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

exports.helloWorld = onRequest((request, response) => {
  response.send("Hello from Firebase!");
});

exports.sendMessageNotification = onDocumentCreated(
    "chats/{chatId}/messages/{messageId}",
    async (event) => {
      const snap = event.data;
    const message = snap.data();
      const chatId = event.params.chatId;
    const senderId = message.senderId;
    const text = message.text;

      const db = admin.firestore();

      const chatDoc = await db.collection("chats").doc(chatId).get();
    const participants = chatDoc.data().participants;

      const recipientId = participants.find((id) => id !== senderId);
      if (!recipientId) return;

      const userDoc = await db.collection("users").doc(recipientId).get();
    const fcmToken = userDoc.data().fcmToken;
      if (!fcmToken) return;

      const senderDoc = await db.collection("users").doc(senderId).get();
      const senderName = senderDoc.data().fullName || "New Message";

    const payload = {
      notification: {
        title: senderName,
        body: text,
      },
      data: {
          type: "chat",
        chatId: chatId,
      },
    };

    await admin.messaging().sendToDevice(fcmToken, payload);
    },
);

exports.updateHubPopularityScores = onSchedule("every 24 hours", async () => {
  const db = admin.firestore();
  const hubsSnapshot = await db.collection("hubs").get();
  const usersSnapshot = await db.collection("users").get();
  const postsSnapshot = await db.collection("posts").get();

  const now = admin.firestore.Timestamp.now();
  const sevenDaysAgo = admin.firestore.Timestamp.fromMillis(
      now.toMillis() - 7 * 24 * 60 * 60 * 1000,
  );

  for (const hubDoc of hubsSnapshot.docs) {
    const hubId = hubDoc.id;

    // Count members
    let memberCount = 0;
    usersSnapshot.docs.forEach((userDoc) => {
      const joinedHubs = userDoc.get("joinedHubs") || [];
      if (joinedHubs.includes(hubId)) {
        memberCount++;
      }
    });

    // Count recent posts
    let recentPosts = 0;
    postsSnapshot.docs.forEach((postDoc) => {
      if (postDoc.get("hubId") === hubId) {
        const postingTime = postDoc.get("postingTime");
        if (
          postingTime &&
          postingTime.toMillis &&
          postingTime.toMillis() >= sevenDaysAgo.toMillis()
        ) {
          recentPosts++;
        }
      }
    });

    const popularityScore = memberCount + recentPosts * 2;

    await db.collection("hubs").doc(hubId).update({popularityScore});
  }

  console.log("Updated popularity scores for all hubs.");
});

// Scheduled function to update trending scores for posts every 8 hours
exports.updatePostTrendingScores = onSchedule("every 8 hours", async () => {
  const db = admin.firestore();
  const postsSnapshot = await db.collection("posts").get();
  const now = admin.firestore.Timestamp.now();

  for (const postDoc of postsSnapshot.docs) {
    const postId = postDoc.id;
    const postData = postDoc.data();
    const postingTime = postData.postingTime;

    // Get engagement metrics
    const upvotes = postData.upvotes || 0;
    const downvotes = postData.downvotes || 0;
    const commentCount = postData.commentCount || 0;
    const shareCount = postData.shareCount || 0;

    // Refined formula components
    const baseScore = Math.log10(Math.max(upvotes * 1.2 - downvotes * 1.5, 1));
    const commentScore = commentCount * 1.0;
    const shareScore = shareCount * 0.8;
    const velocityBonus = Math.min((upvotes + commentCount + shareCount) * 0.5, 20);

    // Time decay calculation
    let timeDecay = 0;
    if (postingTime) {
      const hoursSincePosted = (now.toMillis() - postingTime.toMillis()) /
          (1000 * 60 * 60);
      timeDecay = Math.max(0, hoursSincePosted * 0.8);
    }

    // Final trending score
    const trendingScore = baseScore + commentScore + shareScore + velocityBonus - timeDecay;

    // Update post document with trending score
    await db.collection("posts").doc(postId).update({trendingScore});
  }

  console.log("Updated trending scores for all posts (Refined formula).");
});

exports.sendMilestoneNotification = onDocumentCreated(
  'notifications/{notificationId}',
  async (event) => {
    const notification = event.data.data();
    if (!notification || notification.type !== 'milestone') return;

    const recipientId = notification.recipientId;
    const postId = notification.postId;
    const milestone = notification.milestone;

    // Get recipient's FCM token
    const userDoc = await admin.firestore().collection('users').doc(recipientId).get();
    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;

    const payload = {
      notification: {
        title: 'Your post is trending!',
        body: `Your post just reached ${milestone} positive reactions! Keep it up!`,
      },
      data: {
        type: 'milestone',
        postId: postId,
        milestone: milestone ? milestone.toString() : '',
      },
    };

    await admin.messaging().sendToDevice(fcmToken, payload);
  }
);
