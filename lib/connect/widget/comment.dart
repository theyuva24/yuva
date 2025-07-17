// comment.dart
// Consolidated comment system: model, backend, and UI (excluding voting)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'voting.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'dart:async';

// --- MODEL ---
class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userProfileImage;
  final String content;
  final DateTime timestamp;
  final int upvotes;
  final int downvotes;
  final int score;
  final String? parentCommentId;
  final List<Comment> replies;
  final bool edited;
  final bool deleted;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfileImage,
    required this.content,
    required this.timestamp,
    required this.upvotes,
    required this.downvotes,
    required this.score,
    this.parentCommentId,
    this.replies = const [],
    this.edited = false,
    this.deleted = false,
  });

  factory Comment.fromFirestore(
    Map<String, dynamic> data,
    String id, {
    List<Comment> replies = const [],
  }) {
    return Comment(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userProfileImage: data['userProfileImage'] ?? '',
      content: data['commentContent'] ?? '',
      timestamp:
          (data['commentTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      upvotes: data['upvotes'] ?? 0,
      downvotes: data['downvotes'] ?? 0,
      score: data['score'] ?? 0,
      parentCommentId: data['parentCommentId'],
      replies: replies,
      edited: data['edited'] ?? false,
      deleted: data['deleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'commentContent': content,
      'commentTime': Timestamp.fromDate(timestamp),
      'upvotes': upvotes,
      'downvotes': downvotes,
      'score': score,
      'parentCommentId': parentCommentId,
      'edited': edited,
      'deleted': deleted,
    };
  }
}

List<Comment> buildCommentTree(List<Comment> flatComments) {
  final Map<String, List<Comment>> childrenMap = {};
  final List<Comment> roots = [];
  for (final comment in flatComments) {
    if (comment.parentCommentId == null) {
      roots.add(comment);
    } else {
      childrenMap.putIfAbsent(comment.parentCommentId!, () => []).add(comment);
    }
  }
  Comment attachReplies(Comment comment) {
    final replies = childrenMap[comment.id] ?? [];
    return Comment(
      id: comment.id,
      userId: comment.userId,
      userName: comment.userName,
      userProfileImage: comment.userProfileImage,
      content: comment.content,
      timestamp: comment.timestamp,
      upvotes: comment.upvotes,
      downvotes: comment.downvotes,
      score: comment.score,
      parentCommentId: comment.parentCommentId,
      replies: replies.map(attachReplies).toList(),
      edited: comment.edited,
      deleted: comment.deleted,
    );
  }

  return roots.map(attachReplies).toList();
}

// --- BACKEND LOGIC ---
class CommentService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add comment to a post
  Future<void> addComment(
    String postId,
    String commentContent, {
    String? parentCommentId,
  }) async {
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
    await firestore.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
    // Notification logic can be added here if needed
  }

  // Fetch comments for a post
  Stream<List<Comment>> getCommentsStream(String postId) {
    return firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('commentTime', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
          final List<Comment> flat = [];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            String userName = 'Anonymous';
            String userProfileImage = '';
            try {
              final userDoc =
                  await firestore.collection('users').doc(data['userId']).get();
              if (userDoc.exists) {
                final userData = userDoc.data()!;
                userName = userData['fullName'] ?? 'Anonymous';
                userProfileImage = userData['profilePicUrl'] ?? '';
              }
            } catch (_) {}
            flat.add(
              Comment.fromFirestore({
                ...data,
                'userName': userName,
                'userProfileImage': userProfileImage,
              }, doc.id),
            );
          }
          return buildCommentTree(flat);
        });
  }
}

// --- UI WIDGETS ---
class CommentTree extends StatelessWidget {
  final List<Comment> comments;
  final void Function(String parentId, String replyText)? onReply;
  final void Function(Comment comment)? onEdit;
  final void Function(Comment comment)? onDelete;
  final void Function(Comment comment)? onReport;
  final int depth;
  final String postId;
  final void Function(bool focused)? onAnyReplyFocusChanged;

  const CommentTree({
    Key? key,
    required this.comments,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.depth = 0,
    required this.postId,
    this.onAnyReplyFocusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          comments
              .map(
                (comment) => CommentCard(
                  comment: comment,
                  depth: depth,
                  onReply: onReply,
                  onEdit: onEdit,
                  onDelete: onDelete,
                  onReport: onReport,
                  postId: postId,
                  onAnyReplyFocusChanged: onAnyReplyFocusChanged,
                ),
              )
              .toList(),
    );
  }
}

class CommentCard extends StatefulWidget {
  final Comment comment;
  final int depth;
  final void Function(String parentId, String replyText)? onReply;
  final void Function(Comment comment)? onEdit;
  final void Function(Comment comment)? onDelete;
  final void Function(Comment comment)? onReport;
  final String postId;
  final void Function(bool focused)? onAnyReplyFocusChanged;

  const CommentCard({
    Key? key,
    required this.comment,
    this.depth = 0,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onReport,
    required this.postId,
    this.onAnyReplyFocusChanged,
  }) : super(key: key);

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  bool collapsed = false;
  bool showReplyField = false;
  final TextEditingController replyController = TextEditingController();
  bool expanded = false;
  final VotingService _votingService = VotingService();
  final FocusNode _replyFocusNode = FocusNode();
  late final KeyboardVisibilityController _keyboardVisibilityController;
  late final StreamSubscription<bool> _keyboardSubscription;

  @override
  void dispose() {
    replyController.dispose();
    _replyFocusNode.dispose();
    _keyboardSubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _replyFocusNode.addListener(_handleReplyFocusChange);
    _keyboardVisibilityController = KeyboardVisibilityController();
    _keyboardSubscription = _keyboardVisibilityController.onChange.listen((
      visible,
    ) {
      if (!visible && _replyFocusNode.hasFocus) {
        _replyFocusNode.unfocus();
        if (showReplyField) {
          setState(() {
            showReplyField = false;
          });
        }
        if (widget.onAnyReplyFocusChanged != null) {
          widget.onAnyReplyFocusChanged!(false);
        }
      }
    });
  }

  void _handleReplyFocusChange() {
    if (widget.onAnyReplyFocusChanged != null) {
      widget.onAnyReplyFocusChanged!(_replyFocusNode.hasFocus);
    }
    // If the reply field loses focus, close it and restore the bottom field
    if (!_replyFocusNode.hasFocus && showReplyField) {
      setState(() {
        showReplyField = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final isDeleted = comment.deleted;
    final isEdited = comment.edited;
    void handleReplySubmit() async {
      if (replyController.text.trim().isEmpty || widget.onReply == null) return;
      widget.onReply!(comment.id, replyController.text.trim());
      replyController.clear();
      setState(() => showReplyField = false);
      if (widget.onAnyReplyFocusChanged != null) {
        widget.onAnyReplyFocusChanged!(false);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Draw vertical lines for each depth level
              for (int i = 0; i < widget.depth; i++)
                Container(
                  width: 12,
                  child: VerticalDivider(
                    thickness: 2,
                    color: Colors.grey[300],
                    width: 12,
                  ),
                ),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 0,
                  ),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundImage:
                                  comment.userProfileImage.isNotEmpty
                                      ? NetworkImage(comment.userProfileImage)
                                      : null,
                              child:
                                  comment.userProfileImage.isEmpty
                                      ? const Icon(Icons.person, size: 16)
                                      : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              comment.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimeAgo(comment.timestamp),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            if (isEdited)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text(
                                  '(edited)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (!isDeleted)
                          _buildTruncatedComment(context, comment.content)
                        else
                          const Text(
                            '[deleted]',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        Row(
                          children: [
                            if (!isDeleted)
                              VotingBar(
                                type: VotingTargetType.comment,
                                postId: widget.postId,
                                commentId: comment.id,
                                initialUpvotes: comment.upvotes,
                                initialDownvotes: comment.downvotes,
                                initialScore: comment.score,
                                initiallyUpvoted:
                                    false, // You can implement logic to check if user has upvoted
                                initiallyDownvoted:
                                    false, // You can implement logic to check if user has downvoted
                                votingService: _votingService,
                                onVoteChanged: null,
                              ),
                            TextButton(
                              onPressed:
                                  isDeleted
                                      ? null
                                      : () => setState(() {
                                        showReplyField = !showReplyField;
                                        if (showReplyField) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                FocusScope.of(
                                                  context,
                                                ).requestFocus(_replyFocusNode);
                                              });
                                        } else {
                                          replyController.clear();
                                          _replyFocusNode.unfocus();
                                          if (widget.onAnyReplyFocusChanged !=
                                              null) {
                                            widget.onAnyReplyFocusChanged!(
                                              false,
                                            );
                                          }
                                        }
                                      }),
                              child: const Text(
                                'Reply',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            if (widget.onEdit != null && !isDeleted)
                              IconButton(
                                icon: const Icon(Icons.edit, size: 16),
                                onPressed: () => widget.onEdit!(comment),
                                tooltip: 'Edit',
                              ),
                            if (widget.onDelete != null && !isDeleted)
                              IconButton(
                                icon: const Icon(Icons.delete, size: 16),
                                onPressed: () => widget.onDelete!(comment),
                                tooltip: 'Delete',
                              ),
                            if (widget.onReport != null)
                              IconButton(
                                icon: const Icon(Icons.flag, size: 16),
                                onPressed: () => widget.onReport!(comment),
                                tooltip: 'Report',
                              ),
                          ],
                        ),
                        if (showReplyField && !isDeleted)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: replyController,
                                    focusNode: _replyFocusNode,
                                    decoration: InputDecoration(
                                      hintText: 'Write a reply...',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                      isDense: true,
                                    ),
                                    minLines: 1,
                                    maxLines: 1,
                                    style: const TextStyle(fontSize: 14),
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => handleReplySubmit(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send, size: 18),
                                  onPressed: handleReplySubmit,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!collapsed && comment.replies.isNotEmpty)
          CommentTree(
            comments: comment.replies,
            onReply: widget.onReply,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
            onReport: widget.onReport,
            depth: widget.depth + 1,
            postId: widget.postId,
            onAnyReplyFocusChanged: widget.onAnyReplyFocusChanged,
          ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.year}/${dateTime.month}/${dateTime.day}';
  }

  Widget _buildTruncatedComment(BuildContext context, String content) {
    const int maxLines = 3;
    final textSpan = TextSpan(
      text: content,
      style: const TextStyle(fontSize: 14),
    );
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width - 100);
    final isOverflowing = textPainter.didExceedMaxLines;
    if (expanded || !isOverflowing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content, style: const TextStyle(fontSize: 14)),
          if (isOverflowing)
            GestureDetector(
              onTap: () => setState(() => expanded = false),
              child: const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Show less',
                  style: TextStyle(color: Colors.blue, fontSize: 13),
                ),
              ),
            ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content,
            style: const TextStyle(fontSize: 14),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
          GestureDetector(
            onTap: () => setState(() => expanded = true),
            child: const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                'Read more',
                style: TextStyle(color: Colors.blue, fontSize: 13),
              ),
            ),
          ),
        ],
      );
    }
  }
}
