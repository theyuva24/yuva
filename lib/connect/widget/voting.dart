// All voting logic, UI, and backend integration must be implemented here only.
// Do not implement voting anywhere else in the codebase.
//
// If you need to add or change voting features, do it in this file.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../universal/theme/app_theme.dart';
import '../service/notification_service.dart';

// --- Models ---
class Post {
  final String id;
  final String userName;
  final String userProfileImage;
  final String hubId;
  final String hubName;
  final String hubProfileImage;
  final String postContent;
  final String timestamp;
  final int upvotes;
  final int downvotes;
  final int commentCount;
  final int shareCount;
  final String? postImage;
  final String postOwnerId;

  Post({
    required this.id,
    required this.userName,
    required this.userProfileImage,
    required this.hubId,
    required this.hubName,
    required this.hubProfileImage,
    required this.postContent,
    required this.timestamp,
    required this.upvotes,
    required this.downvotes,
    required this.commentCount,
    required this.shareCount,
    this.postImage,
    required this.postOwnerId,
  });
}

// Remove the Comment class and buildCommentTree function from this file.
// If any code needs Comment or buildCommentTree, import 'comment.dart' as comment and use comment.Comment and comment.buildCommentTree.

// --- Enums ---
enum VoteType { upvote, downvote }

VoteType? voteTypeFromString(String? s) {
  if (s == 'upvote') return VoteType.upvote;
  if (s == 'downvote') return VoteType.downvote;
  return null;
}

String voteTypeToString(VoteType? v) {
  if (v == VoteType.upvote) return 'upvote';
  if (v == VoteType.downvote) return 'downvote';
  return '';
}

class VoteState {
  final int upvotes;
  final int downvotes;
  final int score;
  final VoteType? userVote;
  VoteState({
    required this.upvotes,
    required this.downvotes,
    required this.score,
    required this.userVote,
  });
}

VoteState calculateVoteState({
  required VoteState prev,
  required VoteType action,
}) {
  int upvotes = prev.upvotes;
  int downvotes = prev.downvotes;
  int score = prev.score;
  VoteType? userVote = prev.userVote;

  if (userVote == action) {
    // Remove vote
    if (action == VoteType.upvote) {
      upvotes -= 1;
      score -= 1;
    } else {
      downvotes -= 1;
      score += 1;
    }
    userVote = null;
  } else {
    // Change or new vote
    if (userVote == VoteType.upvote) {
      upvotes -= 1;
      score -= 1;
    } else if (userVote == VoteType.downvote) {
      downvotes -= 1;
      score += 1;
    }
    if (action == VoteType.upvote) {
      upvotes += 1;
      score += 1;
    } else {
      downvotes += 1;
      score -= 1;
    }
    userVote = action;
  }
  return VoteState(
    upvotes: upvotes,
    downvotes: downvotes,
    score: score,
    userVote: userVote,
  );
}

// --- Service ---
class VotingService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Simple in-memory rate limiter (per user, per post/comment, per second)
  static final Map<String, DateTime> _lastVoteTimestamps = {};

  bool _isVoteAllowed(String userId, String targetId) {
    final now = DateTime.now();
    final key = '$userId|$targetId';
    final last = _lastVoteTimestamps[key];
    if (last != null && now.difference(last) < const Duration(seconds: 1)) {
      return false;
    }
    _lastVoteTimestamps[key] = now;
    return true;
  }

  // Vote on a post
  Future<void> voteOnPost(String postId, VoteType voteType) async {
    int maxRetries = 5;
    int attempt = 0;
    while (true) {
      try {
        final user = _auth.currentUser;
        if (user == null) throw Exception('User not authenticated');
        if (!_isVoteAllowed(user.uid, postId)) {
          throw Exception('You are voting too quickly. Please wait a moment.');
        }

        final postRef = firestore.collection('posts').doc(postId);
        final voteRef = postRef.collection('voteInteractions').doc(user.uid);

        await firestore.runTransaction((transaction) async {
          final voteSnapshot = await transaction.get(voteRef);
          final postSnapshot = await transaction.get(postRef);
          if (!postSnapshot.exists) {
            throw Exception('Post does not exist');
          }
          final postData = postSnapshot.data() as Map<String, dynamic>;
          int upvotes = postData['upvotes'] ?? 0;
          int downvotes = postData['downvotes'] ?? 0;
          int score = postData['score'] ?? 0;
          final postOwnerId = postData['userId'] as String?;

          VoteType? currentVote;
          if (voteSnapshot.exists) {
            currentVote = voteTypeFromString(voteSnapshot.data()?['voteType']);
          }
          final prevState = VoteState(
            upvotes: upvotes,
            downvotes: downvotes,
            score: score,
            userVote: currentVote,
          );
          final newState = calculateVoteState(
            prev: prevState,
            action: voteType,
          );

          if (currentVote == voteType) {
            transaction.delete(voteRef);
          } else if (currentVote != null) {
            transaction.update(voteRef, {
              'voteType': voteTypeToString(voteType),
              'voteTime': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.set(voteRef, {
              'userId': user.uid,
              'voteType': voteTypeToString(voteType),
              'voteTime': FieldValue.serverTimestamp(),
            });
          }
          transaction.update(postRef, {
            'upvotes': newState.upvotes,
            'downvotes': newState.downvotes,
            'score': newState.score,
          });
        });
        // Send notification to post owner if not self
        final postSnapshot =
            await firestore.collection('posts').doc(postId).get();
        final postData = postSnapshot.data() as Map<String, dynamic>?;
        final postOwnerId = postData?['userId'] as String?;
        // REMOVE: No more per-upvote notification here
        // if (postOwnerId != null && postOwnerId != user.uid) {
        //   await _notificationService.addNotification(
        //     recipientId: postOwnerId,
        //     type: 'vote',
        //     postId: postId,
        //     senderId: user.uid,
        //     senderName: user.displayName ?? 'Someone',
        //   );
        // }
        break; // Success, exit retry loop
      } catch (e) {
        if (attempt < maxRetries) {
          attempt++;
          final delay = Duration(milliseconds: 200 * (1 << (attempt - 1)));
          await Future.delayed(delay);
        } else {
          throw Exception(
            'Failed to vote after  [${attempt + 1}] attempts: $e',
          );
        }
      }
    }
  }

  // Vote on a comment
  Future<void> voteOnComment(
    String postId,
    String commentId,
    VoteType voteType,
  ) async {
    int maxRetries = 5;
    int attempt = 0;
    while (true) {
      try {
        final user = _auth.currentUser;
        if (user == null) throw Exception('User not authenticated');
        if (!_isVoteAllowed(user.uid, commentId)) {
          throw Exception('You are voting too quickly. Please wait a moment.');
        }

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

          VoteType? currentVote;
          if (voteSnapshot.exists) {
            currentVote = voteTypeFromString(voteSnapshot.data()?['voteType']);
          }
          final prevState = VoteState(
            upvotes: upvotes,
            downvotes: downvotes,
            score: score,
            userVote: currentVote,
          );
          final newState = calculateVoteState(
            prev: prevState,
            action: voteType,
          );

          if (currentVote == voteType) {
            transaction.delete(voteRef);
          } else if (currentVote != null) {
            transaction.update(voteRef, {
              'voteType': voteTypeToString(voteType),
              'voteTime': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.set(voteRef, {
              'userId': user.uid,
              'voteType': voteTypeToString(voteType),
              'voteTime': FieldValue.serverTimestamp(),
            });
          }
          transaction.update(commentRef, {
            'upvotes': newState.upvotes,
            'downvotes': newState.downvotes,
            'score': newState.score,
          });
        });
        // Send notification to comment owner if not self
        final commentSnapshot =
            await firestore
                .collection('posts')
                .doc(postId)
                .collection('comments')
                .doc(commentId)
                .get();
        final commentData = commentSnapshot.data() as Map<String, dynamic>?;
        final commentOwnerId = commentData?['userId'] as String?;
        if (commentOwnerId != null && commentOwnerId != user.uid) {
          await _notificationService.addNotification(
            recipientId: commentOwnerId,
            type: 'vote',
            postId: postId,
            senderId: user.uid,
            senderName: user.displayName ?? 'Someone',
          );
        }
        break; // Success, exit retry loop
      } catch (e) {
        if (attempt < maxRetries) {
          attempt++;
          final delay = Duration(milliseconds: 200 * (1 << (attempt - 1)));
          await Future.delayed(delay);
        } else {
          throw Exception(
            'Failed to vote on comment after ${attempt + 1} attempts: $e',
          );
        }
      }
    }
  }
}

/// Type of voting target
enum VotingTargetType { post, comment }

/// A reusable voting bar for both posts and comments
class VotingBar extends StatefulWidget {
  final VotingTargetType type;
  final String postId;
  final String? commentId; // null for posts
  final int initialUpvotes;
  final int initialDownvotes;
  final int initialScore;
  final bool initiallyUpvoted;
  final bool initiallyDownvoted;
  final VotingService votingService;
  final void Function(int upvotes, int downvotes, int score)? onVoteChanged;

  const VotingBar({
    super.key,
    required this.type,
    required this.postId,
    this.commentId,
    required this.initialUpvotes,
    required this.initialDownvotes,
    required this.initialScore,
    required this.initiallyUpvoted,
    required this.initiallyDownvoted,
    required this.votingService,
    this.onVoteChanged,
  });

  @override
  State<VotingBar> createState() => _VotingBarState();
}

class _VotingBarState extends State<VotingBar> {
  late int _upvotes;
  late int _downvotes;
  late int _score;
  late bool _isUpvoted;
  late bool _isDownvoted;
  bool _isVoting = false;
  bool _isRateLimited = false;
  String? _voteError;
  DateTime? _lastVoteTime;
  late VoteType? _userVote;

  @override
  void initState() {
    super.initState();
    _upvotes = widget.initialUpvotes;
    _downvotes = widget.initialDownvotes;
    _score = widget.initialScore;
    _isUpvoted = widget.initiallyUpvoted;
    _isDownvoted = widget.initiallyDownvoted;
    _userVote =
        _isUpvoted
            ? VoteType.upvote
            : _isDownvoted
            ? VoteType.downvote
            : null;
    _fetchUserVoteState();
  }

  Future<void> _fetchUserVoteState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      DocumentReference voteRef;
      if (widget.type == VotingTargetType.post) {
        voteRef = FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('voteInteractions')
            .doc(user.uid);
      } else {
        voteRef = FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(widget.commentId)
            .collection('voteInteractions')
            .doc(user.uid);
      }
      final voteSnap = await voteRef.get();
      if (voteSnap.exists) {
        final data = voteSnap.data() as Map<String, dynamic>?;
        final voteType = voteTypeFromString(data?['voteType']);
        setState(() {
          _userVote = voteType;
          _isUpvoted = voteType == VoteType.upvote;
          _isDownvoted = voteType == VoteType.downvote;
        });
      }
    } catch (_) {
      // Ignore errors for now
    }
  }

  Future<void> _handleVote(String voteTypeStr) async {
    final now = DateTime.now();
    if (_lastVoteTime != null &&
        now.difference(_lastVoteTime!) < const Duration(milliseconds: 500)) {
      return;
    }
    if (_isVoting || _isRateLimited) return;
    _lastVoteTime = now;
    setState(() {
      _isVoting = true;
      _voteError = null;
      _isRateLimited = false;
    });
    // Store previous state for rollback
    final prevState = VoteState(
      upvotes: _upvotes,
      downvotes: _downvotes,
      score: _score,
      userVote: _userVote,
    );
    final VoteType action = voteTypeFromString(voteTypeStr)!;
    // Optimistic update
    final newState = calculateVoteState(prev: prevState, action: action);
    setState(() {
      _upvotes = newState.upvotes;
      _downvotes = newState.downvotes;
      _score = newState.score;
      _userVote = newState.userVote;
      _isUpvoted = _userVote == VoteType.upvote;
      _isDownvoted = _userVote == VoteType.downvote;
    });
    try {
      if (widget.type == VotingTargetType.post) {
        await widget.votingService.voteOnPost(widget.postId, action);
      } else {
        await widget.votingService.voteOnComment(
          widget.postId,
          widget.commentId!,
          action,
        );
      }
      widget.onVoteChanged?.call(_upvotes, _downvotes, _score);
    } catch (e) {
      final errorMsg = e.toString();
      setState(() {
        _upvotes = prevState.upvotes;
        _downvotes = prevState.downvotes;
        _score = prevState.score;
        _userVote = prevState.userVote;
        _isUpvoted = _userVote == VoteType.upvote;
        _isDownvoted = _userVote == VoteType.downvote;
        if (errorMsg.contains('voting too quickly')) {
          _voteError = 'You are voting too quickly. Please wait.';
          _isRateLimited = true;
        } else {
          _voteError = 'Failed to vote. Tap to retry.';
        }
      });
      if (_isRateLimited) {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _isRateLimited = false;
          _voteError = null;
        });
      }
    } finally {
      setState(() {
        _isVoting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: _isUpvoted ? 'Upvoted' : 'Upvote',
          selected: _isUpvoted,
          child: IconButton(
            onPressed:
                (_isVoting || _isRateLimited)
                    ? null
                    : () => _handleVote('upvote'),
            icon:
                _isUpvoted
                    ? Icon(
                      Icons.arrow_upward,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    )
                    : Icon(
                      Icons.arrow_upward_outlined,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                      size: 22,
                    ),
            tooltip: _isUpvoted ? 'You upvoted' : 'Upvote',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Text(
            '$_score',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? AppThemeDark.textPrimary
                      : AppThemeLight.textPrimary,
            ),
          ),
        ),
        Semantics(
          label: _isDownvoted ? 'Downvoted' : 'Downvote',
          selected: _isDownvoted,
          child: IconButton(
            onPressed:
                (_isVoting || _isRateLimited)
                    ? null
                    : () => _handleVote('downvote'),
            icon:
                _isDownvoted
                    ? Icon(
                      Icons.arrow_downward,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppThemeDark.ctaText
                              : AppThemeLight.ctaText,
                      size: 22,
                    )
                    : Icon(
                      Icons.arrow_downward_outlined,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppThemeDark.textSecondary
                              : AppThemeLight.textSecondary,
                      size: 22,
                    ),
            tooltip: _isDownvoted ? 'You downvoted' : 'Downvote',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        if (_voteError != null)
          GestureDetector(
            onTap: () => _handleVote(_isUpvoted ? 'upvote' : 'downvote'),
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.error,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppThemeDark.errorText
                            : AppThemeLight.errorText,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _voteError!,
                    style: TextStyle(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppThemeDark.errorText
                              : AppThemeLight.errorText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
