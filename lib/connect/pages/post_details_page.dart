import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/post_service.dart' hide Comment, buildCommentTree;
import '../widget/post_card.dart';
import '../widget/voting.dart';
import '../widget/comment.dart' as comment;

class PostDetailsPage extends StatefulWidget {
  final String postId;
  final String userName;
  final String userProfileImage;
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
  final String postType;
  final String? linkUrl;
  final Map<String, dynamic>? pollData;

  const PostDetailsPage({
    Key? key,
    required this.postId,
    required this.userName,
    required this.userProfileImage,
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
    required this.postType,
    this.linkUrl,
    this.pollData,
  }) : super(key: key);

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  final PostService _postService = PostService();
  List<comment.Comment> _comments = [];
  bool _loadingComments = true;
  String? _commentsError;
  final TextEditingController _commentController = TextEditingController();
  bool _isPostingComment = false;
  final ValueNotifier<bool> _replyBoxFocused = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFieldFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyBoxFocused.dispose();
    _scrollController.dispose();
    _commentFieldFocusNode.dispose();
    super.dispose();
  }

  void _fetchComments() {
    setState(() {
      _loadingComments = true;
      _commentsError = null;
    });
    _postService.firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('commentTime', descending: false)
        .snapshots()
        .listen((snapshot) async {
          try {
            final List<comment.Comment> flat = [];
            for (final doc in snapshot.docs) {
              final data = doc.data();
              // Fetch user info for each comment
              String userName = 'Anonymous';
              String userProfileImage = '';
              try {
                final userDoc =
                    await _postService.firestore
                        .collection('users')
                        .doc(data['userId'])
                        .get();
                if (userDoc.exists) {
                  final userData = userDoc.data()!;
                  userName = userData['fullName'] ?? 'Anonymous';
                  userProfileImage = userData['profilePicUrl'] ?? '';
                }
              } catch (_) {}
              flat.add(
                comment.Comment.fromFirestore({
                  ...data,
                  'userName': userName,
                  'userProfileImage': userProfileImage,
                }, doc.id),
              );
            }
            setState(() {
              _comments = comment.buildCommentTree(flat);
              _loadingComments = false;
            });
          } catch (e) {
            setState(() {
              _commentsError = 'Failed to load comments: $e';
              _loadingComments = false;
            });
          }
        });
  }

  Future<void> _handleCommentReply(String parentId, String replyText) async {
    if (replyText.trim().isEmpty) return;
    try {
      await _postService.addComment(
        widget.postId,
        replyText.trim(),
        parentCommentId: parentId,
      );
      // Optionally show a snackbar or update UI
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add reply: $e')));
    }
  }

  Future<void> _handleAddComment() async {
    if (_commentController.text.trim().isEmpty || _isPostingComment) return;
    setState(() {
      _isPostingComment = true;
    });
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await _postService.addComment(
        widget.postId,
        _commentController.text.trim(),
      );
      _commentController.clear();
      FocusScope.of(context).unfocus(); // Close the keyboard
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Comment added successfully!')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to add comment: $e')),
      );
    } finally {
      setState(() {
        _isPostingComment = false;
      });
    }
  }

  void _scrollToCommentField() {
    // Scroll to the bottom and focus the comment field
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_commentFieldFocusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PostCard(
                postId: widget.postId,
                userName: widget.userName,
                userProfileImage: widget.userProfileImage,
                hubName: widget.hubName,
                hubProfileImage: widget.hubProfileImage,
                postContent: widget.postContent,
                timestamp: widget.timestamp,
                upvotes: widget.upvotes,
                downvotes: widget.downvotes,
                commentCount: widget.commentCount,
                shareCount: widget.shareCount,
                postImage: widget.postImage,
                postOwnerId: widget.postOwnerId,
                postType: widget.postType,
                linkUrl: widget.linkUrl,
                pollData: widget.pollData,
                onCardTap: null,
                onCommentTap: _scrollToCommentField,
              ),
              const SizedBox(height: 16),
              const Divider(),
              if (_loadingComments)
                const Center(child: CircularProgressIndicator()),
              if (_commentsError != null)
                Text(
                  _commentsError!,
                  style: const TextStyle(color: Colors.red),
                ),
              if (!_loadingComments && _comments.isEmpty)
                const Text('No comments yet. Be the first to comment!'),
              if (!_loadingComments && _comments.isNotEmpty)
                comment.CommentTree(
                  comments: _comments,
                  onReply: _handleCommentReply,
                  postId: widget.postId,
                  onAnyReplyFocusChanged: (focused) {
                    _replyBoxFocused.value = focused;
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: _replyBoxFocused,
        builder: (context, replyFocused, child) {
          if (replyFocused) return SizedBox.shrink();
          return Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              top: 6,
            ),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFieldFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
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
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleAddComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isPostingComment
                      ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: Color(0xFF00F6FF),
                        ),
                        onPressed: _handleAddComment,
                      ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
