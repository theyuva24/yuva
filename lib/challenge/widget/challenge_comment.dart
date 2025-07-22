import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  });

  factory ChallengeComment.fromFirestore(
    Map<String, dynamic> data,
    String id, {
    List<ChallengeComment> replies = const [],
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
    );
  }

  return roots.map(attachReplies).toList();
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
}

// --- UI WIDGETS ---
class ChallengeCommentSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Only a small gap (e.g., 4px) between input and keyboard, never negative
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
            challengeId: challengeId,
            submissionId: submissionId,
            scrollController: scrollController,
            // onReply is handled by the input field now
            onReply: null,
          ),
        ),
        Divider(height: 1, color: Theme.of(context).dividerColor),
        Padding(
          padding: EdgeInsets.only(bottom: safeBottomPadding),
          child: _CommentInputField(
            challengeId: challengeId,
            submissionId: submissionId,
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
  final void Function(String commentId, String userName)? onReply;
  const _ChallengeCommentList({
    Key? key,
    required this.challengeId,
    required this.submissionId,
    this.scrollController,
    this.onReply,
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
                    (c) => _ChallengeCommentCard(
                      comment: c,
                      onReply: (commentId, userName) {
                        // Use a notification to the input field if needed
                        // (not needed for this stateless parent)
                      },
                    ),
                  )
                  .toList(),
        );
      },
    );
  }
}

class _CommentInputField extends StatefulWidget {
  final String challengeId;
  final String submissionId;
  const _CommentInputField({
    Key? key,
    required this.challengeId,
    required this.submissionId,
  }) : super(key: key);

  @override
  State<_CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<_CommentInputField> {
  final ChallengeCommentService _service = ChallengeCommentService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _replyToCommentId;
  String? _replyToUserName;

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
      parentCommentId: _replyToCommentId,
    );
    setState(() {
      _controller.clear();
      _replyToCommentId = null;
      _replyToUserName = null;
    });
    _focusNode.unfocus();
  }

  void _handleReply(String commentId, String userName) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToUserName = userName;
    });
    FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText:
                    _replyToUserName != null
                        ? 'Reply to @${_replyToUserName}'
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
            icon: Icon(Icons.send, color: Theme.of(context).iconTheme.color),
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}

class _ChallengeCommentCard extends StatelessWidget {
  final ChallengeComment comment;
  final void Function(String commentId, String userName) onReply;
  const _ChallengeCommentCard({
    Key? key,
    required this.comment,
    required this.onReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Text(
                comment.userName,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimeAgo(comment.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(comment.content, style: Theme.of(context).textTheme.bodyMedium),
          Row(
            children: [
              TextButton(
                onPressed: () => onReply(comment.id, comment.userName),
                child: Text(
                  'Reply',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Column(
                children:
                    comment.replies
                        .map(
                          (r) => _ChallengeCommentCard(
                            comment: r,
                            onReply: onReply,
                          ),
                        )
                        .toList(),
              ),
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
