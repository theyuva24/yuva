import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import 'hub_service.dart';
import '../models/hub_model.dart';
import 'notification_service.dart';
import '../widget/comment.dart';

List<Post>? _cachedPosts;
DateTime? _cacheTime;
const Duration _cacheDuration = Duration(minutes: 5);

void clearPostsCache() {
  _cachedPosts = null;
  _cacheTime = null;
}

class PostService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Helper to ensure all engagement fields are present
  Map<String, dynamic> ensureEngagementFields(Map<String, dynamic> data) {
    return {
      'upvotes': data['upvotes'] ?? 0,
      'downvotes': data['downvotes'] ?? 0,
      'score': data['score'] ?? 0,
      'commentCount': data['commentCount'] ?? 0,
      'shareCount': data['shareCount'] ?? 0,
      'linkClickCount': data['linkClickCount'] ?? 0,
    };
  }

  // Create a new post
  Future<String> createPost({
    required String hubId,
    required String hubName,
    required String postContent,
    String? postImageUrl,
    Map<String, dynamic>? pollData,
    String? linkUrl,
    required String postType,
    String? userName,
    String? userProfileImage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final postData = {
        'userId': user.uid,
        'hubId': hubId,
        'hubName': hubName,
        'postContent': postContent,
        'postingTime': FieldValue.serverTimestamp(),
        'postImageUrl': postImageUrl,
        'pollData': pollData,
        'linkUrl': linkUrl,
        'postType': postType,
        'userName': userName,
        'userProfileImage': userProfileImage,
        'anonymous': (userName == 'Anonymous'),
        ...ensureEngagementFields({}), // Always set all engagement fields
      };

      final docRef = await firestore.collection('posts').add(postData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  /// Fetch posts with in-memory caching
  Future<List<Post>> fetchPosts({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedPosts != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedPosts!;
    }
    // Fetch from Firestore
    final snapshot =
        await firestore
            .collection('posts')
            .orderBy('postingTime', descending: true)
            .get();
    final posts = <Post>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      posts.add(
        Post(
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
          postType: data['postType'] ?? 'text',
          linkUrl: data['linkUrl'],
          pollData: data['pollData'],
        ),
      );
    }
    _cachedPosts = posts;
    _cacheTime = DateTime.now();
    return posts;
  }

  // Get all posts with real-time updates
  Stream<List<Post>> getPostsStream() {
    final hubService = HubService();
    return firestore
        .collection('posts')
        .orderBy('postingTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final posts = <Post>[];
          // Collect all unique hubIds from posts
          final hubIds =
              snapshot.docs
                  .map((doc) => doc.data()['hubId'] as String?)
                  .whereType<String>()
                  .toSet();
          // Fetch all hubs in one go
          final hubsMap = <String, Hub>{};
          if (hubIds.isNotEmpty) {
            final hubsSnap =
                await firestore
                    .collection('hubs') // Standardized to lowercase
                    .where(FieldPath.documentId, whereIn: hubIds.toList())
                    .get();
            for (final doc in hubsSnap.docs) {
              final data = doc.data();
              hubsMap[doc.id] = Hub(
                id: doc.id,
                name: data['name'] ?? '',
                description: data['description'] ?? '',
                imageUrl: data['imageUrl'] ?? '',
              );
            }
          }
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final userId = data['userId'] as String?;
            String userName = 'Anonymous';
            String userProfileImage = '';
            if (userId != null) {
              try {
                final userDoc =
                    await firestore.collection('users').doc(userId).get();
                if (userDoc.exists) {
                  final userData = userDoc.data()!;
                  userName = userData['fullName'] ?? 'Anonymous';
                  userProfileImage = userData['profilePicUrl'] ?? '';
                }
              } catch (e) {
                print('Failed to fetch user data for $userId: $e');
              }
            }
            // Fetch latest hub info
            final hubId = data['hubId'] as String? ?? '';
            final hub = hubsMap[hubId];
            final hubName = hub?.name ?? data['hubName'] ?? '';
            final hubProfileImage =
                hub?.imageUrl ?? data['hubProfileImage'] ?? '';
            posts.add(
              Post(
                id: doc.id,
                userName: userName,
                userProfileImage: userProfileImage,
                hubId: hubId,
                hubName: hubName,
                hubProfileImage: hubProfileImage,
                postContent: data['postContent'] ?? '',
                timestamp: _formatTimestamp(data['postingTime']),
                upvotes: data['upvotes'] ?? 0,
                downvotes: data['downvotes'] ?? 0,
                commentCount: data['commentCount'] ?? 0,
                shareCount: data['shareCount'] ?? 0,
                postImage: data['postImageUrl'],
                postOwnerId: data['userId'] ?? '',
                postType: data['postType'] ?? 'text',
                linkUrl: data['linkUrl'],
                pollData: data['pollData'],
              ),
            );
          }
          return posts;
        });
  }

  // Vote on a post
  Future<void> voteOnPost(String postId, String voteType) async {
    print(
      '[DEBUG] voteOnPost called with postId: $postId, voteType: $voteType',
    );
    int maxRetries = 2;
    int attempt = 0;
    while (true) {
      try {
        final user = _auth.currentUser;
        print(
          '[DEBUG] Current user: ${user?.uid}, isAuthenticated: ${user != null}',
        );
        if (user == null) throw Exception('User not authenticated');

        final postRef = firestore.collection('posts').doc(postId);
        final voteRef = postRef.collection('voteInteractions').doc(user.uid);

        await firestore.runTransaction((transaction) async {
          print('[DEBUG] Running Firestore transaction for voting');
          final voteSnapshot = await transaction.get(voteRef);
          final postSnapshot = await transaction.get(postRef);
          if (!postSnapshot.exists) {
            print('[DEBUG] Post does not exist');
            throw Exception('Post does not exist');
          }
          final postData = postSnapshot.data() as Map<String, dynamic>;
          print('[DEBUG] Post data: ' + postData.toString());
          int upvotes = postData['upvotes'] ?? 0;
          int downvotes = postData['downvotes'] ?? 0;
          int score = postData['score'] ?? 0;
          int commentCount = postData['commentCount'] ?? 0;
          int shareCount = postData['shareCount'] ?? 0;
          int linkClickCount = postData['linkClickCount'] ?? 0;
          final postOwnerId = postData['userId'] as String?;

          if (voteSnapshot.exists) {
            final currentVote = voteSnapshot.data()?['voteType'];
            print('[DEBUG] Existing vote found: ' + currentVote.toString());
            if (currentVote == voteType) {
              // Remove vote
              print('[DEBUG] Removing vote');
              transaction.delete(voteRef);
              if (voteType == 'upvote') {
                upvotes -= 1;
                score -= 1;
              } else if (voteType == 'downvote') {
                downvotes -= 1;
                score += 1;
              }
            } else {
              // Change vote
              print('[DEBUG] Changing vote from $currentVote to $voteType');
              transaction.update(voteRef, {
                'voteType': voteType,
                'voteTime': FieldValue.serverTimestamp(),
              });
              if (currentVote == 'upvote') {
                upvotes -= 1;
                score -= 1;
              } else if (currentVote == 'downvote') {
                downvotes -= 1;
                score += 1;
              }
              if (voteType == 'upvote') {
                upvotes += 1;
                score += 1;
              } else if (voteType == 'downvote') {
                downvotes += 1;
                score -= 1;
              }
            }
          } else {
            // New vote
            print('[DEBUG] Creating new vote');
            transaction.set(voteRef, {
              'userId': user.uid,
              'voteType': voteType,
              'voteTime': FieldValue.serverTimestamp(),
            });
            if (voteType == 'upvote') {
              upvotes += 1;
              score += 1;
            } else if (voteType == 'downvote') {
              downvotes += 1;
              score -= 1;
            }
            // Send notification only for upvotes and not for own post
            if (voteType == 'upvote' &&
                postOwnerId != null &&
                postOwnerId != user.uid) {
              final userDoc =
                  await firestore.collection('users').doc(user.uid).get();
              final senderName = userDoc.data()?['fullName'] ?? 'Someone';
              print('[DEBUG] Sending notification to post owner: $postOwnerId');
              await _notificationService.addNotification(
                recipientId: postOwnerId,
                type: 'like',
                postId: postId,
                senderId: user.uid,
                senderName: senderName,
              );
            }
          }
          print('[DEBUG] Updating post engagement fields');
          // Only update engagement fields: upvotes, downvotes, score
          transaction.update(postRef, {
            'upvotes': upvotes,
            'downvotes': downvotes,
            'score': score,
          });
        });
        print('[DEBUG] Vote transaction completed successfully');
        break; // Success, exit retry loop
      } catch (e, stack) {
        print('[DEBUG] Exception in voteOnPost (attempt ${attempt + 1}): $e');
        print('[DEBUG] Stack trace: $stack');
        if (attempt < maxRetries) {
          attempt++;
          print('[DEBUG] Retrying voteOnPost (attempt $attempt)...');
          await Future.delayed(const Duration(milliseconds: 200));
        } else {
          throw Exception('Failed to vote after ${attempt + 1} attempts: $e');
        }
      }
    }
  }

  // Vote on a comment
  Future<void> voteOnComment(
    String postId,
    String commentId,
    String voteType,
  ) async {
    int maxRetries = 2;
    int attempt = 0;
    while (true) {
      try {
        final user = _auth.currentUser;
        if (user == null) throw Exception('User not authenticated');

        final commentRef = firestore
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId);
        final voteRef = commentRef.collection('voteInteractions').doc(user.uid);

        await firestore.runTransaction((transaction) async {
          final voteSnapshot = await transaction.get(voteRef);
          final commentSnapshot = await transaction.get(commentRef);
          if (!commentSnapshot.exists) {
            throw Exception('Comment does not exist');
          }
          final commentData = commentSnapshot.data() as Map<String, dynamic>;
          int upvotes = commentData['upvotes'] ?? 0;
          int downvotes = commentData['downvotes'] ?? 0;
          int score = commentData['score'] ?? 0;
          final commentOwnerId = commentData['userId'] as String?;

          if (voteSnapshot.exists) {
            final currentVote = voteSnapshot.data()?['voteType'];
            if (currentVote == voteType) {
              // Remove vote
              transaction.delete(voteRef);
              if (voteType == 'upvote') {
                upvotes -= 1;
                score -= 1;
              } else if (voteType == 'downvote') {
                downvotes -= 1;
                score += 1;
              }
            } else {
              // Change vote
              transaction.update(voteRef, {
                'voteType': voteType,
                'voteTime': FieldValue.serverTimestamp(),
              });
              if (currentVote == 'upvote') {
                upvotes -= 1;
                score -= 1;
              } else if (currentVote == 'downvote') {
                downvotes -= 1;
                score += 1;
              }
              if (voteType == 'upvote') {
                upvotes += 1;
                score += 1;
              } else if (voteType == 'downvote') {
                downvotes += 1;
                score -= 1;
              }
            }
          } else {
            // New vote
            transaction.set(voteRef, {
              'userId': user.uid,
              'voteType': voteType,
              'voteTime': FieldValue.serverTimestamp(),
            });
            if (voteType == 'upvote') {
              upvotes += 1;
              score += 1;
            } else if (voteType == 'downvote') {
              downvotes += 1;
              score -= 1;
            }
            // (Optional) Send notification to comment owner if not self
            // if (voteType == 'upvote' && commentOwnerId != null && commentOwnerId != user.uid) {
            //   // Add notification logic here
            // }
          }
          transaction.update(commentRef, {
            'upvotes': upvotes,
            'downvotes': downvotes,
            'score': score,
          });
        });
        break; // Success
      } catch (e) {
        if (attempt < maxRetries) {
          attempt++;
          await Future.delayed(const Duration(milliseconds: 200));
        } else {
          throw Exception(
            'Failed to vote on comment after ${attempt + 1} attempts: $e',
          );
        }
      }
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

      final commentData = {
        'userId': user.uid,
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

      // Send notification to post owner (not for own comment)
      final postDoc = await firestore.collection('posts').doc(postId).get();
      final postOwnerId = postDoc.data()?['userId'];
      if (postOwnerId != null && postOwnerId != user.uid) {
        final userDoc = await firestore.collection('users').doc(user.uid).get();
        final senderName = userDoc.data()?['fullName'] ?? 'Someone';
        await _notificationService.addNotification(
          recipientId: postOwnerId,
          type: 'comment',
          postId: postId,
          senderId: user.uid,
          senderName: senderName,
          commentText: commentContent,
        );
      }
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

  /// Maintenance: Recount and repair vote counts for all posts
  Future<void> recountAllPostVotes() async {
    final postsSnap = await firestore.collection('posts').get();
    for (final postDoc in postsSnap.docs) {
      final postId = postDoc.id;
      final voteInteractionsSnap =
          await firestore
              .collection('posts')
              .doc(postId)
              .collection('voteInteractions')
              .get();
      int upvotes = 0;
      int downvotes = 0;
      for (final voteDoc in voteInteractionsSnap.docs) {
        final voteType = voteDoc.data()['voteType'];
        if (voteType == 'upvote') upvotes++;
        if (voteType == 'downvote') downvotes++;
      }
      final score = upvotes - downvotes;
      await firestore.collection('posts').doc(postId).update({
        'upvotes': upvotes,
        'downvotes': downvotes,
        'score': score,
      });
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
