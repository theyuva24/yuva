// comment.dart
// Consolidated comment system: model, backend, and UI (excluding voting)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'voting.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';

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
  final bool isAnonymous;

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
    this.isAnonymous = false,
  });

  factory Comment.fromFirestore(
    Map<String, dynamic> data,
    String id, {
    List<Comment> replies = const [],
  }) {
    return Comment(
      id: id,
      userId: data['userId'] ?? '',
      userName:
          (data['isAnonymous'] ?? false)
              ? 'Anonymous'
              : (data['userName'] ?? 'Anonymous'),
      userProfileImage:
          (data['isAnonymous'] ?? false)
              ? ''
              : (data['userProfileImage'] ?? ''),
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
      isAnonymous: data['isAnonymous'] ?? false,
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
      'isAnonymous': isAnonymous,
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
      isAnonymous: comment.isAnonymous,
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
    bool isAnonymous = false,
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
      'isAnonymous': isAnonymous,
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
  final void Function(String parentId, String replyText, bool isAnonymous)?
  onReply;
  final void Function(Comment comment)? onEdit;
  final void Function(Comment comment)? onDelete;
  final void Function(Comment comment)? onReport;
  final int depth;
  final String postId;
  final void Function(bool focused)? onAnyReplyFocusChanged;
  final List<bool> isLastList;

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
    this.isLastList = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          comments.asMap().entries.map((entry) {
            final idx = entry.key;
            final comment = entry.value;
            final isLast = idx == comments.length - 1;
            return CommentCard(
              comment: comment,
              depth: depth,
              isLastList: [...isLastList, isLast],
              onReply: onReply,
              onEdit: onEdit,
              onDelete: onDelete,
              onReport: onReport,
              postId: postId,
              onAnyReplyFocusChanged: onAnyReplyFocusChanged,
            );
          }).toList(),
    );
  }
}

class CommentCard extends StatefulWidget {
  final Comment comment;
  final int depth;
  final List<bool> isLastList;
  final void Function(String parentId, String replyText, bool isAnonymous)?
  onReply;
  final void Function(Comment comment)? onEdit;
  final void Function(Comment comment)? onDelete;
  final void Function(Comment comment)? onReport;
  final String postId;
  final void Function(bool focused)? onAnyReplyFocusChanged;

  const CommentCard({
    Key? key,
    required this.comment,
    this.depth = 0,
    this.isLastList = const [],
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
  bool _isReplyAnonymous = false;

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
      widget.onReply!(
        comment.id,
        replyController.text.trim(),
        _isReplyAnonymous,
      );
      replyController.clear();
      setState(() => showReplyField = false);
      if (widget.onAnyReplyFocusChanged != null) {
        widget.onAnyReplyFocusChanged!(false);
      }
    }

    // Reddit-style: vertical lines for nesting
    final List<Widget> nestingLines = List.generate(widget.depth, (i) {
      // For parent levels, only draw a line if there are more siblings at that level
      if (i < widget.isLastList.length - 1) {
        if (!widget.isLastList[i]) {
          return Container(
            width: 2,
            height: double.infinity,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        } else {
          return SizedBox(width: 10);
        }
      }
      // For the deepest level, always draw a line
      return Container(
        width: 2,
        height: double.infinity,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor,
          borderRadius: BorderRadius.circular(1),
        ),
      );
    });

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...List.generate(
              widget.depth,
              (i) => Container(
                width: 2,
                height: double.infinity,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).dividerColor, // Thin, light grey line
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage:
                              comment.userProfileImage.isNotEmpty
                                  ? CachedNetworkImageProvider(
                                    comment.userProfileImage,
                                  )
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
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        if (isEdited)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              '(edited)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (!isDeleted)
                      _buildTruncatedComment(context, comment.content)
                    else
                      Text(
                        '[deleted]',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
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
                            initiallyUpvoted: false,
                            initiallyDownvoted: false,
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
                                        widget.onAnyReplyFocusChanged!(false);
                                      }
                                    }
                                  }),
                          child: Text('Reply', style: TextStyle(fontSize: 12)),
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
                                  contentPadding: const EdgeInsets.symmetric(
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
                            Row(
                              children: [
                                Text('Anon', style: TextStyle(fontSize: 12)),
                                Switch(
                                  value: _isReplyAnonymous,
                                  onChanged: (val) {
                                    setState(() {
                                      _isReplyAnonymous = val;
                                    });
                                  },
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  activeColor:
                                      Theme.of(context).colorScheme.secondary,
                                  inactiveThumbColor:
                                      Theme.of(context).colorScheme.primary,
                                  inactiveTrackColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.2),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.send, size: 18),
                              onPressed: handleReplySubmit,
                            ),
                          ],
                        ),
                      ),
                    // Render replies inside the same background, indented
                    if (!collapsed && comment.replies.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: CommentTree(
                          comments: comment.replies,
                          onReply: widget.onReply,
                          onEdit: widget.onEdit,
                          onDelete: widget.onDelete,
                          onReport: widget.onReport,
                          depth: widget.depth + 1,
                          postId: widget.postId,
                          onAnyReplyFocusChanged: widget.onAnyReplyFocusChanged,
                          isLastList: widget.isLastList,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Show less',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                  ),
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
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Read more',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}

// Utility to count all comments and replies recursively
typedef CommentCounter = int Function(List<Comment> comments);

int countAllComments(List<Comment> comments) {
  int count = 0;
  for (final comment in comments) {
    count += 1; // count this comment
    count += countAllComments(comment.replies); // count all replies recursively
  }
  return count;
}
