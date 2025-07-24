import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add a notification for a user
  Future<void> addNotification({
    required String recipientId,
    required String type, // 'like', 'comment', or 'milestone'
    required String postId,
    required String senderId,
    required String senderName,
    String? commentText,
    int? milestone, // Add milestone for milestone notifications
    String?
    challengeId, // Add challengeId for challenge submission notifications
  }) async {
    final notificationData = {
      'recipientId': recipientId,
      'type': type,
      'postId': postId,
      'senderId': senderId,
      'senderName': senderName,
      'commentText': commentText,
      'milestone': milestone, // Store milestone if present
      'challengeId': challengeId, // Store challengeId if present
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    };
    await _firestore.collection('notifications').add(notificationData);
  }

  // Get notifications for the current user
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }
}
