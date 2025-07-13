import 'package:cloud_firestore/cloud_firestore.dart';

class Submission {
  final String id;
  final String challengeId;
  final String userId;
  final String? mediaUrl;
  final String caption;
  final Timestamp timestamp;
  final String status;

  Submission({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.mediaUrl,
    required this.caption,
    required this.timestamp,
    required this.status,
  });

  factory Submission.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Submission(
      id: doc.id,
      challengeId: data['challengeId'] ?? '',
      userId: data['userId'] ?? '',
      mediaUrl: data['mediaUrl'],
      caption: data['caption'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'userId': userId,
      'mediaUrl': mediaUrl,
      'caption': caption,
      'timestamp': timestamp,
      'status': status,
    };
  }
}
