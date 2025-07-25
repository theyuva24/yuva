import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import '../../connect/service/notification_service.dart';
import '../../universal/theme/app_theme.dart';

// --- MODEL ---
class ChallengeComment {
  final String id;
  final String userId;
  final String userName;
  final String userProfileImage;
  final String content;
  final DateTime timestamp;
  final String? parentCommentId;
  final List<ChallengeComment> replies;
  final bool edited;
  final bool deleted;
  final int likeCount;

  ChallengeComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfileImage,
    required this.content,
    required this.timestamp,
    this.parentCommentId,
    this.replies = const [],
    this.edited = false,
    this.deleted = false,
    this.likeCount = 0,
  });

  factory ChallengeComment.fromFirestore(
    Map<String, dynamic> data,
    String id, {
    List<ChallengeComment> replies = const [],
    int likeCount = 0,
  }) {
    return ChallengeComment(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userProfileImage: data['userProfileImage'] ?? '',
      content: data['commentContent'] ?? '',
      timestamp:
          (data['commentTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentCommentId: data['parentCommentId'],
      replies: replies,
      edited: data['edited'] ?? false,
      deleted: data['deleted'] ?? false,
      likeCount: data['likeCount'] ?? likeCount,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'commentContent': content,
      'commentTime': Timestamp.fromDate(timestamp),
      'parentCommentId': parentCommentId,
      'edited': edited,
      'deleted': deleted,
      'likeCount': likeCount,
    };
  }
}

List<ChallengeComment> buildChallengeCommentTree(
  List<ChallengeComment> flatComments,
) {
  final Map<String, List<ChallengeComment>> childrenMap = {};
  final List<ChallengeComment> roots = [];
  for (final comment in flatComments) {
    if (comment.parentCommentId == null) {
      roots.add(comment);
    } else {
      childrenMap.putIfAbsent(comment.parentCommentId!, () => []).add(comment);
    }
  }
  ChallengeComment attachReplies(ChallengeComment comment) {
    final replies = childrenMap[comment.id] ?? [];
    // Sort replies by score (likes, replies, recency)
    replies.sort((a, b) => _commentScore(b).compareTo(_commentScore(a)));
    return ChallengeComment(
      id: comment.id,
      userId: comment.userId,
      userName: comment.userName,
      userProfileImage: comment.userProfileImage,
      content: comment.content,
      timestamp: comment.timestamp,
      parentCommentId: comment.parentCommentId,
      replies: replies.map(attachReplies).toList(),
      edited: comment.edited,
      deleted: comment.deleted,
      likeCount: comment.likeCount,
    );
  }

  // Sort top-level comments by score
  roots.sort((a, b) => _commentScore(b).compareTo(_commentScore(a)));
  return roots.map(attachReplies).toList();
}

// Simple score formula for sorting replies
int _commentScore(ChallengeComment comment) {
  int likes = comment.likeCount;
  int replies = comment.replies.length;
  bool isRecent = DateTime.now().difference(comment.timestamp).inHours < 1;
  return (likes * 1) + (replies * 4) + (isRecent ? 1 : 0);
}

List<ChallengeComment> sortRepliesByScore(List<ChallengeComment> replies) {
  final sorted = List<ChallengeComment>.from(replies);
  sorted.sort((a, b) => _commentScore(b).compareTo(_commentScore(a)));
  return sorted;
}

// --- SERVICE ---
class ChallengeCommentService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add comment to a challenge submission
  Future<void> addComment(
    String challengeId,
    String submissionId,
    String commentContent, {
    String? parentCommentId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final userDoc = await firestore.collection('users').doc(user.uid).get();
    final userName = userDoc.data()?['fullName'] ?? 'Anonymous';
    final userProfileImage = userDoc.data()?['profilePicUrl'] ?? '';
    final commentData = {
      'userId': user.uid,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'commentContent': commentContent,
      'commentTime': FieldValue.serverTimestamp(),
      'parentCommentId': parentCommentId,
      'edited': false,
      'deleted': false,
    };
    await firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('challenge_submission')
        .doc(submissionId)
        .collection('comments')
        .add(commentData);
    await firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('challenge_submission')
        .doc(submissionId)
        .update({'commentCount': FieldValue.increment(1)});

    // Send notification to submission owner only for direct comments (not replies)
    if (parentCommentId == null) {
      final submissionDoc =
          await firestore
              .collection('challenges')
              .doc(challengeId)
              .collection('challenge_submission')
              .doc(submissionId)
              .get();
      final submissionOwnerId = submissionDoc.data()?['userId'];
      if (submissionOwnerId != null && submissionOwnerId != user.uid) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get()
            .then((userDoc) async {
              final senderName = userDoc.data()?['fullName'] ?? 'Someone';
              await NotificationService().addNotification(
                recipientId: submissionOwnerId,
                type: 'comment',
                postId: submissionId,
                senderId: user.uid,
                senderName: senderName,
                commentText: commentContent,
              );
            });
      }
    }
  }

  // Fetch comments for a challenge submission
  Stream<List<ChallengeComment>> getCommentsStream(
    String challengeId,
    String submissionId,
  ) {
    return firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('challenge_submission')
        .doc(submissionId)
        .collection('comments')
        .orderBy('commentTime', descending: false)
        .snapshots()
        .map((snapshot) {
          final List<ChallengeComment> flat = [];
          for (final doc in snapshot.docs) {
            final data = doc.data();
            flat.add(ChallengeComment.fromFirestore(data, doc.id));
          }
          return buildChallengeCommentTree(flat);
        });
  }

  // Like a comment
  Future<void> likeComment(
    String challengeId,
    String submissionId,
    String commentId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    await firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('challenge_submission')
        .doc(submissionId)
        .collection('comments')
        .doc(commentId)
        .collection('likeInteractions')
        .doc(user.uid)
        .set({'liked': true, 'timestamp': FieldValue.serverTimestamp()});
    // Increment likeCount field
    await firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('challenge_submission')
        .doc(submissionId)
        .collection('comments')
        .doc(commentId)
        .update({'likeCount': FieldValue.increment(1)});
  }

  // Unlike a comment
  Future<void> unlikeComment(
    String challengeId,
    String submissionId,
    String commentId,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    await firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('challenge_submission')
        .doc(submissionId)
        .collection('comments')
        .doc(commentId)
        .collection('likeInteractions')
        .doc(user.uid)
        .delete();
    // Decrement likeCount field
    await firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('challenge_submission')
        .doc(submissionId)
        .collection('comments')
        .doc(commentId)
        .update({'likeCount': FieldValue.increment(-1)});
  }

  // Stream like count for a comment
  Stream<int> getCommentLikeCount(
    String challengeId,
    String submissionId,
    String commentId,
  ) {
    return firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('challenge_submission')
        .doc(submissionId)
        .collection('comments')
        .doc(commentId)
        .collection('likeInteractions')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // Stream whether current user liked this comment
  Stream<bool> isCommentLikedByCurrentUser(
    String challengeId,
    String submissionId,
    String commentId,
  ) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);
    return firestore
        .collection('challenges')
        .doc(challengeId)
        .collection('challenge_submission')
        .doc(submissionId)
        .collection('comments')
        .doc(commentId)
        .collection('likeInteractions')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists);
  }
}

// --- UI WIDGETS ---
class ChallengeCommentSection extends StatefulWidget {
  final String challengeId;
  final String submissionId;
  final ScrollController? scrollController;
  const ChallengeCommentSection({
    Key? key,
    required this.challengeId,
    required this.submissionId,
    this.scrollController,
  }) : super(key: key);

  @override
  State<ChallengeCommentSection> createState() =>
      _ChallengeCommentSectionState();
}

class _ChallengeCommentSectionState extends State<ChallengeCommentSection> {
  String? _replyToCommentId;
  String? _replyToUserName;
  final _inputFieldKey = GlobalKey<_CommentInputFieldState>();

  void _setReplyTarget(String commentId, String userName) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUserName = userName;
    });
    // Focus the input field after the frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFieldKey.currentState?.focusInput();
    });
  }

  void _clearReplyTarget() {
    setState(() {
      _replyToCommentId = null;
      _replyToUserName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottomPadding = bottomInset > 0 ? bottomInset + 4.0 : 4.0;
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).dividerColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(
          'Comments',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _ChallengeCommentList(
            challengeId: widget.challengeId,
            submissionId: widget.submissionId,
            scrollController: widget.scrollController,
            onReply: _setReplyTarget,
          ),
        ),
        Divider(height: 1, color: Theme.of(context).dividerColor),
        Padding(
          padding: EdgeInsets.only(bottom: safeBottomPadding),
          child: _CommentInputField(
            key: _inputFieldKey,
            challengeId: widget.challengeId,
            submissionId: widget.submissionId,
            replyToCommentId: _replyToCommentId,
            replyToUserName: _replyToUserName,
            onCancelReply: _clearReplyTarget,
            onSend: _clearReplyTarget,
          ),
        ),
      ],
    );
  }
}

class _ChallengeCommentList extends StatelessWidget {
  final String challengeId;
  final String submissionId;
  final ScrollController? scrollController;
  final void Function(String commentId, String userName) onReply;
  const _ChallengeCommentList({
    Key? key,
    required this.challengeId,
    required this.submissionId,
    this.scrollController,
    required this.onReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ChallengeCommentService _service = ChallengeCommentService();
    return StreamBuilder<List<ChallengeComment>>(
      stream: _service.getCommentsStream(challengeId, submissionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final comments = snapshot.data ?? [];
        if (comments.isEmpty) {
          return Center(
            child: Text(
              'No comments yet. Be the first!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          );
        }
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.zero,
          children:
              comments
                  .map(
                    (c) => _ChallengeCommentCard(comment: c, onReply: onReply),
                  )
                  .toList(),
        );
      },
    );
  }
}

class _ChallengeCommentCard extends StatefulWidget {
  final ChallengeComment comment;
  final void Function(String commentId, String userName) onReply;
  final int nestingLevel;
  const _ChallengeCommentCard({
    Key? key,
    required this.comment,
    required this.onReply,
    this.nestingLevel = 0,
  }) : super(key: key);

  @override
  State<_ChallengeCommentCard> createState() => _ChallengeCommentCardState();
}

class _ChallengeCommentCardState extends State<_ChallengeCommentCard> {
  bool _showReplies = false;

  int _countAllReplies(ChallengeComment comment) {
    int count = comment.replies.length;
    for (final r in comment.replies) {
      count += _countAllReplies(r);
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final onReply = widget.onReply;
    final nestingLevel = widget.nestingLevel;
    final challengeSection =
        context.findAncestorWidgetOfExactType<ChallengeCommentSection>();
    final challengeId = challengeSection?.challengeId ?? '';
    final submissionId = challengeSection?.submissionId ?? '';
    final service = ChallengeCommentService();
    // Subtle background color based on nesting level
    final List<Color> bgColors = [
      Theme.of(context).colorScheme.surface,
      Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.05) ??
          Colors.grey.withOpacity(0.05),
      Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.1) ??
          Colors.grey.withOpacity(0.1),
      Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.2) ??
          Colors.grey.withOpacity(0.2),
    ];
    final bgColor = bgColors[nestingLevel % bgColors.length];
    final totalReplies = _countAllReplies(comment);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
      child: Container(
        decoration: BoxDecoration(
          color:
              nestingLevel == 0
                  ? Theme.of(context).colorScheme.surface
                  : bgColor,
          border:
              nestingLevel > 0
                  ? Border(
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withOpacity(
                        0.10 + 0.08 * (nestingLevel % 3),
                      ),
                      width: 3,
                    ),
                  )
                  : null,
        ),
        margin: EdgeInsets.only(bottom: nestingLevel == 0 ? 10 : 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage:
                      comment.userProfileImage.isNotEmpty
                          ? CachedNetworkImageProvider(comment.userProfileImage)
                          : null,
                  child:
                      comment.userProfileImage.isEmpty
                          ? Icon(
                            Icons.person,
                            size: 18,
                            color: Theme.of(context).iconTheme.color,
                          )
                          : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comment.userName,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimeAgo(comment.timestamp),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      _ExpandableCommentText(
                        text: comment.content,
                        style: Theme.of(context).textTheme.bodyMedium,
                        trimLines: 2,
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed:
                                () => onReply(comment.id, comment.userName),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(36, 18),
                            ),
                            child: Text(
                              'Reply',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Like button and count
                StreamBuilder<int>(
                  stream: service.getCommentLikeCount(
                    challengeId,
                    submissionId,
                    comment.id,
                  ),
                  builder: (context, likeSnap) {
                    final likeCount = likeSnap.data ?? 0;
                    return StreamBuilder<bool>(
                      stream: service.isCommentLikedByCurrentUser(
                        challengeId,
                        submissionId,
                        comment.id,
                      ),
                      builder: (context, likedSnap) {
                        final liked = likedSnap.data ?? false;
                        return Column(
                          children: [
                            IconButton(
                              icon: Icon(
                                liked ? Icons.favorite : Icons.favorite_border,
                                color:
                                    liked
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(context).iconTheme.color,
                                size: 20,
                              ),
                              onPressed: () {
                                if (liked) {
                                  service.unlikeComment(
                                    challengeId,
                                    submissionId,
                                    comment.id,
                                  );
                                } else {
                                  service.likeComment(
                                    challengeId,
                                    submissionId,
                                    comment.id,
                                  );
                                }
                              },
                            ),
                            Text(
                              likeCount > 0 ? likeCount.toString() : '',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Theme.of(context).textTheme.bodySmall?.color
                                        ?.withOpacity(0.6) ??
                                    Colors.grey.withOpacity(0.6),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            if (comment.replies.isNotEmpty && !_showReplies)
              GestureDetector(
                onTap: () => setState(() => _showReplies = true),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, top: 2, bottom: 2),
                  child: Text(
                    'See replies ($totalReplies)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            if (comment.replies.isNotEmpty && _showReplies)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Column(
                  children:
                      sortRepliesByScore(comment.replies)
                          .map(
                            (r) => _ChallengeCommentCard(
                              comment: r,
                              onReply: onReply,
                              nestingLevel: nestingLevel + 1,
                            ),
                          )
                          .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableCommentText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int trimLines;
  const _ExpandableCommentText({
    Key? key,
    required this.text,
    this.style,
    this.trimLines = 2,
  }) : super(key: key);

  @override
  State<_ExpandableCommentText> createState() => _ExpandableCommentTextState();
}

class _ExpandableCommentTextState extends State<_ExpandableCommentText> {
  bool _expanded = false;
  bool _isOverflowing = false;
  String? _truncatedText;
  @override
  void didUpdateWidget(covariant _ExpandableCommentText oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  void _checkOverflow() {
    final textSpan = TextSpan(text: widget.text, style: widget.style);
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: widget.trimLines,
      textDirection: TextDirection.ltr,
      ellipsis: '...',
    )..layout(maxWidth: MediaQuery.of(context).size.width - 80);
    setState(() {
      _isOverflowing = textPainter.didExceedMaxLines;
      if (_isOverflowing) {
        // Find the cutoff point for the visible text
        final pos = textPainter.getPositionForOffset(
          Offset(textPainter.width, textPainter.height),
        );
        final endOffset =
            textPainter.getOffsetBefore(pos.offset) ?? widget.text.length;
        _truncatedText = widget.text.substring(0, endOffset).trim();
      } else {
        _truncatedText = widget.text;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_expanded || !_isOverflowing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.text, style: widget.style),
          if (_isOverflowing)
            GestureDetector(
              onTap: () => setState(() => _expanded = false),
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Show less',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    // Inline 'Read more' at the end of the truncated text
    return RichText(
      text: TextSpan(
        style: widget.style ?? DefaultTextStyle.of(context).style,
        children: [
          TextSpan(
            text: (_truncatedText ?? widget.text).replaceAll(
              RegExp(r'[\s\n]+$'),
              '',
            ),
          ),
          TextSpan(
            text: '... Read more',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            recognizer:
                TapGestureRecognizer()
                  ..onTap = () => setState(() => _expanded = true),
          ),
        ],
      ),
    );
  }
}

class _CommentInputField extends StatefulWidget {
  final String challengeId;
  final String submissionId;
  final String? replyToCommentId;
  final String? replyToUserName;
  final VoidCallback? onCancelReply;
  final VoidCallback? onSend;
  const _CommentInputField({
    Key? key,
    required this.challengeId,
    required this.submissionId,
    this.replyToCommentId,
    this.replyToUserName,
    this.onCancelReply,
    this.onSend,
  }) : super(key: key);

  @override
  State<_CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<_CommentInputField> {
  final ChallengeCommentService _service = ChallengeCommentService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  void focusInput() {
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await _service.addComment(
      widget.challengeId,
      widget.submissionId,
      text,
      parentCommentId: widget.replyToCommentId,
    );
    _controller.clear();
    widget.onSend?.call();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.replyToUserName != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Row(
                children: [
                  Text(
                    'Replying to @${widget.replyToUserName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onCancelReply,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText:
                        widget.replyToUserName != null
                            ? 'Reply to @${widget.replyToUserName}'
                            : 'Add a comment...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).inputDecorationTheme.fillColor ??
                        Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.send,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: _handleSend,
              ),
            ],
          ),
        ],
      ),
    );
  }
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
