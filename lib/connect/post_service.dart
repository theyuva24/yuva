import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_model.dart';

class PostService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new post
  Future<String> createPost({
    required String hubId,
    required String hubName,
    required String postContent,
    String? postImageUrl,
    Map<String, dynamic>? pollData,
    String? linkUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user data from Firestore
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['userName'] ?? 'Anonymous User';

      final postData = {
        'userId': user.uid,
        'userName': userName,
        'hubId': hubId,
        'hubName': hubName,
        'postContent': postContent,
        'postingTime': FieldValue.serverTimestamp(),
        'upvotes': 0,
        'downvotes': 0,
        'score': 0,
        'commentCount': 0,
        'shareCount': 0,
        'postImageUrl': postImageUrl,
        'pollData': pollData,
        'linkUrl': linkUrl,
        'linkClickCount': 0,
      };

      final docRef = await firestore.collection('posts').add(postData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // Get all posts with real-time updates
  Stream<List<Post>> getPostsStream() {
    return firestore
        .collection('posts')
        .orderBy('postingTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Post(
              id: doc.id,
              userName: data['userName'] ?? 'Anonymous',
              userProfileImage: data['userProfileImage'] ?? '',
              hubId: data['hubId'] ?? '',
              hubName: data['hubName'] ?? '',
              hubProfileImage: data['hubProfileImage'] ?? '',
              postContent: data['postContent'] ?? '',
              timestamp: _formatTimestamp(data['postingTime']),
              upvotes: data['upvotes'] ?? 0,
              downvotes: data['downvotes'] ?? 0,
              commentCount: data['commentCount'] ?? 0,
              shareCount: data['shareCount'] ?? 0,
              postImage: data['postImageUrl'],
              postOwnerId: data['userId'] ?? '',
            );
          }).toList();
        });
  }

  // Vote on a post
  Future<void> voteOnPost(String postId, String voteType) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final voteRef = firestore
          .collection('posts')
          .doc(postId)
          .collection('voteInteractions')
          .doc(user.uid);

      final voteDoc = await voteRef.get();
      final postRef = firestore.collection('posts').doc(postId);

      if (voteDoc.exists) {
        // User has already voted
        final currentVote = voteDoc.data()?['voteType'];

        if (currentVote == voteType) {
          // Remove vote
          await voteRef.delete();
          await _updatePostVotes(postRef, voteType, -1);
        } else {
          // Change vote
          await voteRef.update({
            'voteType': voteType,
            'voteTime': FieldValue.serverTimestamp(),
          });
          await _updatePostVotes(postRef, currentVote, -1);
          await _updatePostVotes(postRef, voteType, 1);
        }
      } else {
        // New vote
        await voteRef.set({
          'userId': user.uid,
          'voteType': voteType,
          'voteTime': FieldValue.serverTimestamp(),
        });
        await _updatePostVotes(postRef, voteType, 1);
      }
    } catch (e) {
      throw Exception('Failed to vote: $e');
    }
  }

  // Update post vote counts
  Future<void> _updatePostVotes(
    DocumentReference postRef,
    String? voteType,
    int change,
  ) async {
    if (voteType == 'upvote') {
      await postRef.update({
        'upvotes': FieldValue.increment(change),
        'score': FieldValue.increment(change),
      });
    } else if (voteType == 'downvote') {
      await postRef.update({
        'downvotes': FieldValue.increment(change),
        'score': FieldValue.increment(-change),
      });
    }
  }

  // Add comment to a post
  Future<void> addComment(
    String postId,
    String commentContent, {
    String? parentCommentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user data
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['userName'] ?? 'Anonymous User';

      final commentData = {
        'userId': user.uid,
        'userName': userName,
        'commentContent': commentContent,
        'commentTime': FieldValue.serverTimestamp(),
        'upvotes': 0,
        'downvotes': 0,
        'score': 0,
        'parentCommentId': parentCommentId,
      };

      await firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add(commentData);

      // Update post comment count
      await firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Share a post
  Future<void> sharePost(String postId, {String? platform}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user has already shared this post recently (within 1 hour)
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      final recentShareQuery =
          await firestore
              .collection('posts')
              .doc(postId)
              .collection('shareInteractions')
              .where('userId', isEqualTo: user.uid)
              .where('shareTime', isGreaterThan: oneHourAgo)
              .get();

      if (recentShareQuery.docs.isNotEmpty) {
        // User has shared recently, don't count as new share
        return;
      }

      // Add share interaction
      await firestore
          .collection('posts')
          .doc(postId)
          .collection('shareInteractions')
          .add({
            'userId': user.uid,
            'shareTime': FieldValue.serverTimestamp(),
            'sharePlatform': platform ?? 'unknown',
            'userName': user.displayName ?? 'Anonymous',
          });

      // Update post share count atomically
      await firestore.collection('posts').doc(postId).update({
        'shareCount': FieldValue.increment(1),
        'lastSharedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to share post: $e');
    }
  }

  // Track link click
  Future<void> trackLinkClick(String postId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await firestore.collection('posts').doc(postId).update({
        'linkClickCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to track link click: $e');
    }
  }

  // Vote on poll option
  Future<void> voteOnPoll(String postId, int optionIndex) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final pollRef = firestore
          .collection('posts')
          .doc(postId)
          .collection('pollInteractions')
          .doc(user.uid);

      final pollDoc = await pollRef.get();

      if (pollDoc.exists) {
        // Update existing vote
        await pollRef.update({
          'selectedOption': optionIndex,
          'interactionTime': FieldValue.serverTimestamp(),
        });
      } else {
        // Create new vote
        await pollRef.set({
          'userId': user.uid,
          'selectedOption': optionIndex,
          'interactionTime': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to vote on poll: $e');
    }
  }

  // Report a post
  Future<void> reportPost({
    required String postId,
    required String reason,
    String? additionalDetails,
    required String postContent,
    required String postOwnerId,
    required String postOwnerName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      await firestore.collection('reported_posts').add({
        'postId': postId,
        'reportedBy': user.uid,
        'reportedAt': FieldValue.serverTimestamp(),
        'reason': reason,
        'additionalDetails': additionalDetails,
        'postContent': postContent,
        'postOwnerId': postOwnerId,
        'postOwnerName': postOwnerName,
      });
    } catch (e) {
      throw Exception('Failed to report post: $e');
    }
  }

  // Format timestamp for display
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    final now = DateTime.now();
    final postTime =
        timestamp is Timestamp
            ? timestamp.toDate()
            : DateTime.parse(timestamp.toString());

    final difference = now.difference(postTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
