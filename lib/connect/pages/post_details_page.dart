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

  @override
  void initState() {
    super.initState();
    _fetchComments();
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

  Future<void> _handleCommentReply(String parentId) async {
    final TextEditingController replyController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reply'),
            content: TextField(
              controller: replyController,
              decoration: const InputDecoration(
                hintText: 'Write your reply...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (replyController.text.trim().isNotEmpty) {
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      await _postService.addComment(
                        widget.postId,
                        replyController.text.trim(),
                        parentCommentId: parentId,
                      );
                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Reply added successfully!'),
                        ),
                      );
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Failed to add reply: $e')),
                      );
                    }
                  }
                },
                child: const Text('Reply'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Details')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show the post at the top (reuse PostCard for consistency, with all actions enabled)
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
                onCardTap: null, // Disable navigation
              ),
              const SizedBox(height: 16),
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.comment, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Comments',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                  // You can add onEdit, onDelete, onReport handlers here
                ),
            ],
          ),
        ),
      ),
    );
  }
}
