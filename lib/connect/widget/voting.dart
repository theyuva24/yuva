// All voting logic, UI, and backend integration must be implemented here only.
// Do not implement voting anywhere else in the codebase.
//
// If you need to add or change voting features, do it in this file.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../universal/theme/app_theme.dart';

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

// --- Service ---
class VotingService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Vote on a post
  Future<void> voteOnPost(String postId, String voteType) async {
    int maxRetries = 2;
    int attempt = 0;
    while (true) {
      try {
        final user = _auth.currentUser;
        if (user == null) throw Exception('User not authenticated');

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
          }
          // Only update engagement fields: upvotes, downvotes, score
          transaction.update(postRef, {
            'upvotes': upvotes,
            'downvotes': downvotes,
            'score': score,
          });
        });
        break; // Success, exit retry loop
      } catch (e) {
        if (attempt < maxRetries) {
          attempt++;
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
  String? _voteError;
  DateTime? _lastVoteTime;

  @override
  void initState() {
    super.initState();
    _upvotes = widget.initialUpvotes;
    _downvotes = widget.initialDownvotes;
    _score = widget.initialScore;
    _isUpvoted = widget.initiallyUpvoted;
    _isDownvoted = widget.initiallyDownvoted;
  }

  Future<void> _handleVote(String voteType) async {
    final now = DateTime.now();
    if (_lastVoteTime != null &&
        now.difference(_lastVoteTime!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastVoteTime = now;
    if (_isVoting) return;
    setState(() {
      _isVoting = true;
      _voteError = null;
    });
    // Store previous state for rollback
    final prevUpvoted = _isUpvoted;
    final prevDownvoted = _isDownvoted;
    final prevUpvotes = _upvotes;
    final prevDownvotes = _downvotes;
    final prevScore = _score;
    // Optimistic update
    setState(() {
      if (voteType == 'upvote') {
        if (_isUpvoted) {
          _isUpvoted = false;
          _upvotes--;
          _score--;
        } else {
          _isUpvoted = true;
          _isDownvoted = false;
          _upvotes++;
          if (_isDownvoted) {
            _downvotes--;
            _score += 2;
          } else {
            _score++;
          }
        }
      } else {
        if (_isDownvoted) {
          _isDownvoted = false;
          _downvotes--;
          _score++;
        } else {
          _isDownvoted = true;
          _isUpvoted = false;
          _downvotes++;
          if (_isUpvoted) {
            _upvotes--;
            _score -= 2;
          } else {
            _score--;
          }
        }
      }
    });
    try {
      if (widget.type == VotingTargetType.post) {
        await widget.votingService.voteOnPost(widget.postId, voteType);
      } else {
        await widget.votingService.voteOnComment(
          widget.postId,
          widget.commentId!,
          voteType,
        );
      }
      widget.onVoteChanged?.call(_upvotes, _downvotes, _score);
    } catch (e) {
      setState(() {
        _isUpvoted = prevUpvoted;
        _isDownvoted = prevDownvoted;
        _upvotes = prevUpvotes;
        _downvotes = prevDownvotes;
        _score = prevScore;
        _voteError = 'Failed to vote. Tap to retry.';
      });
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
            onPressed: _isVoting ? null : () => _handleVote('upvote'),
            icon:
                _isUpvoted
                    ? const Icon(
                      Icons.arrow_upward,
                      color: AppThemeLight.primary,
                      size: 22,
                    )
                    : const Icon(
                      Icons.arrow_upward_outlined,
                      color: AppThemeLight.textLight,
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        Semantics(
          label: _isDownvoted ? 'Downvoted' : 'Downvote',
          selected: _isDownvoted,
          child: IconButton(
            onPressed: _isVoting ? null : () => _handleVote('downvote'),
            icon:
                _isDownvoted
                    ? const Icon(
                      Icons.arrow_downward,
                      color: AppThemeLight.primary,
                      size: 22,
                    )
                    : const Icon(
                      Icons.arrow_downward_outlined,
                      color: AppThemeLight.textLight,
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
                  const Icon(Icons.error, color: Colors.red, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _voteError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
