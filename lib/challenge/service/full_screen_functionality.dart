import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../profile/services/profile_service.dart';
import '../../connect/service/notification_service.dart';
import 'package:flutter/material.dart';
import '../../profile/public_profile_page.dart';

class FullScreenFunctionality {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final NotificationService _notificationService = NotificationService();

  /// Like or unlike a submission (toggle)
  static Future<void> likeSubmission({
    required String challengeId,
    required String submissionId,
    required String submissionOwnerId,
    required BuildContext context,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final likeRef = _firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('challenge_submission')
        .doc(submissionId)
        .collection('likeInteractions')
        .doc(user.uid);
    final submissionRef = _firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('challenge_submission')
        .doc(submissionId);
    await _firestore.runTransaction((transaction) async {
      final likeSnap = await transaction.get(likeRef);
      final submissionSnap = await transaction.get(submissionRef);
      if (!submissionSnap.exists) throw Exception('Submission does not exist');
      int likeCount = submissionSnap.data()?['likeCount'] ?? 0;
      if (likeSnap.exists) {
        // Unlike
        transaction.delete(likeRef);
        likeCount = (likeCount - 1).clamp(0, 1 << 30);
      } else {
        // Like
        transaction.set(likeRef, {
          'userId': user.uid,
          'likeTime': FieldValue.serverTimestamp(),
        });
        likeCount++;
        // Send notification if not self
        if (submissionOwnerId != user.uid) {
          final userDoc =
              await _firestore.collection('users').doc(user.uid).get();
          final senderName = userDoc.data()?['fullName'] ?? 'Someone';
          await _notificationService.addNotification(
            recipientId: submissionOwnerId,
            type: 'like',
            postId: submissionId,
            senderId: user.uid,
            senderName: senderName,
          );
        }
      }
      transaction.update(submissionRef, {'likeCount': likeCount});
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Like updated!')));
  }

  /// Share a submission (rate-limited to 1 per hour per user)
  static Future<void> shareSubmission({
    required String challengeId,
    required String submissionId,
    required String submissionOwnerId,
    required BuildContext context,
    String? platform,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final shareRef = _firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('challenge_submission')
        .doc(submissionId)
        .collection('shareInteractions');
    final submissionRef = _firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('challenge_submission')
        .doc(submissionId);
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final recentShareQuery =
        await shareRef
            .where('userId', isEqualTo: user.uid)
            .where('shareTime', isGreaterThan: oneHourAgo)
            .get();
    if (recentShareQuery.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have already shared this recently.')),
      );
      return;
    }
    await shareRef.add({
      'userId': user.uid,
      'shareTime': FieldValue.serverTimestamp(),
      'sharePlatform': platform ?? 'unknown',
    });
    await submissionRef.update({
      'shareCount': FieldValue.increment(1),
      'lastSharedAt': FieldValue.serverTimestamp(),
    });
    // Optionally send notification
    if (submissionOwnerId != user.uid) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final senderName = userDoc.data()?['fullName'] ?? 'Someone';
      await _notificationService.addNotification(
        recipientId: submissionOwnerId,
        type: 'share',
        postId: submissionId,
        senderId: user.uid,
        senderName: senderName,
      );
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Submission shared!')));
  }

  /// View a user's profile (navigate to profile page)
  static Future<void> viewProfile({
    required BuildContext context,
    required String userId,
  }) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PublicProfilePage(uid: userId)),
    );
  }
}
