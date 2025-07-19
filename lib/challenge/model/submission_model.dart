import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
part 'submission_model.g.dart';

@HiveType(typeId: 1)
class Submission {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String challengeId;
  @HiveField(2)
  final String userId;
  @HiveField(3)
  final String? mediaUrl;
  @HiveField(4)
  final String caption;
  @HiveField(5)
  final Timestamp timestamp;
  @HiveField(6)
  final String? status;
  @HiveField(7)
  final String? thumbnailUrl;
  @HiveField(8)
  final String? mediaType; // 'image', 'video', or null

  Submission({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.mediaUrl,
    required this.caption,
    required this.timestamp,
    this.status, // Make status optional
    this.thumbnailUrl,
    this.mediaType,
  });

  factory Submission.fromDocument(DocumentSnapshot doc, {String? challengeId}) {
    final data = doc.data() as Map<String, dynamic>;
    return Submission(
      id: doc.id,
      challengeId: challengeId ?? data['challengeId'] ?? '',
      userId: data['userId'] ?? '',
      mediaUrl: data['mediaUrl'],
      caption: data['caption'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      status: data['status'] ?? 'pending',
      thumbnailUrl: data['thumbnailUrl'],
      mediaType: data['mediaType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mediaUrl': mediaUrl,
      'caption': caption,
      'timestamp': timestamp,
      'status': status,
      'thumbnailUrl': thumbnailUrl,
      'mediaType': mediaType,
      // Note: challengeId is not stored in document since it's implicit in subcollection structure
    };
  }

  // Helper method to determine if this is a video
  bool get isVideo {
    if (mediaType != null) {
      return mediaType == 'video';
    }
    // Fallback to URL extension check
    if (mediaUrl != null) {
      final lower = mediaUrl!.toLowerCase();
      return lower.endsWith('.mp4') ||
          lower.endsWith('.mov') ||
          lower.endsWith('.m3u8') ||
          lower.endsWith('.avi') ||
          lower.endsWith('.mkv');
    }
    return false;
  }

  // Helper method to determine if this is an image
  bool get isImage {
    if (mediaType != null) {
      return mediaType == 'image';
    }
    // Fallback to URL extension check
    if (mediaUrl != null) {
      final lower = mediaUrl!.toLowerCase();
      return lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.gif') ||
          lower.endsWith('.webp');
    }
    return false;
  }

  // Helper method to get the display URL (thumbnail for videos, original for images)
  String? get displayUrl {
    if (isVideo && thumbnailUrl != null && thumbnailUrl!.isNotEmpty) {
      return thumbnailUrl;
    }
    return mediaUrl;
  }
}
