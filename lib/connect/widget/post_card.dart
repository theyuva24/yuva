import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../service/post_service.dart' hide Comment, buildCommentTree;
import '../../profile/profile_page.dart';
import '../pages/hub_details_page.dart';
import '../models/hub_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/post_details_page.dart'; // <-- Add this import
import 'package:google_fonts/google_fonts.dart';
import 'voting.dart';
import 'comment.dart' as comment;

class PostCard extends StatefulWidget {
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
  final VoidCallback? onCardTap; // <-- Add this

  const PostCard({
    super.key,
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
    this.onCardTap, // <-- Add this
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final PostService _postService = PostService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Comments state
  List<comment.Comment> _comments = [];
  bool _loadingComments = true;
  String? _commentsError;
  bool _isSharing = false;

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
              _comments = flat; // No longer need buildCommentTree
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

  Future<void> _handleComment() async {
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Comment'),
            content: TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'Write your comment...',
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
                  if (commentController.text.trim().isNotEmpty) {
                    final navigator = Navigator.of(context);
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    try {
                      await _postService.addComment(
                        widget.postId,
                        commentController.text.trim(),
                      );
                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Comment added successfully!'),
                        ),
                      );
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(content: Text('Failed to add comment: $e')),
                      );
                    }
                  }
                },
                child: const Text('Post'),
              ),
            ],
          ),
    );
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

  Future<void> _handleShare() async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      // Create share content
      String shareText =
          '${widget.userName} shared a post in ${widget.hubName}:\n\n';
      shareText += widget.postContent;

      if (widget.postImage != null) {
        shareText += '\n\n[Image attached]';
      }

      shareText += '\n\nShared via YUVA App';

      // Share the content
      await Share.share(shareText, subject: 'Check out this post from YUVA');

      // Track share in Firestore after successful share
      await _postService.sharePost(widget.postId, platform: 'native_share');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post shared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      String errorMsg = 'Failed to share. Please try again later.';
      if (e.toString().contains('requires an index')) {
        debugPrint('Firestore index error: $e');
        errorMsg = 'Sharing is temporarily unavailable. Please try again soon.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  Future<void> _handleReport() async {
    final List<String> reasons = [
      'Spam',
      'Inappropriate',
      'Harassment',
      'False Information',
      'Other',
    ];
    String? selectedReason;
    String? additionalDetails;
    final TextEditingController detailsController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Post',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...reasons.map(
                      (reason) => RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (val) {
                          setModalState(() {
                            selectedReason = val;
                          });
                        },
                      ),
                    ),
                    if (selectedReason == 'Other')
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextField(
                          controller: detailsController,
                          decoration: const InputDecoration(
                            labelText: 'Please describe the issue',
                            border: OutlineInputBorder(),
                          ),
                          minLines: 2,
                          maxLines: 4,
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed:
                              selectedReason == null
                                  ? null
                                  : () {
                                    additionalDetails =
                                        selectedReason == 'Other'
                                            ? detailsController.text.trim()
                                            : null;
                                    Navigator.pop(context, {
                                      'reason': selectedReason,
                                      'details': additionalDetails,
                                    });
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ).then((result) async {
      if (result != null && result['reason'] != null) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        try {
          await _postService.reportPost(
            postId: widget.postId,
            reason: result['reason'],
            additionalDetails: result['details'],
            postContent: widget.postContent,
            postOwnerId: widget.postOwnerId,
            postOwnerName: widget.userName,
          );
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text(
                  'Thank you for reporting. Our team will review this post.',
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(content: Text('Failed to report post: $e')),
            );
          }
        }
      }
    });
  }

  void _openDetailsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PostDetailsPage(
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
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onCardTap, // Handles navigation for the whole card
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info and hub info
              Row(
                children: [
                  // User profile section
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    ProfilePage(uid: widget.postOwnerId),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              widget.userProfileImage,
                            ),
                            onBackgroundImageError: (exception, stackTrace) {},
                            child:
                                widget.userProfileImage.isEmpty
                                    ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  widget.timestamp,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Hub profile section
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => HubDetailsPage(
                                hub: Hub(
                                  id:
                                      widget
                                          .postId, // Assuming postId is the hubId for now
                                  name: widget.hubName,
                                  description: '',
                                  imageUrl: widget.hubProfileImage,
                                ),
                              ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(widget.hubProfileImage),
                      onBackgroundImageError: (exception, stackTrace) {},
                      child:
                          widget.hubProfileImage.isEmpty
                              ? const Icon(
                                Icons.group,
                                color: Colors.white,
                                size: 20,
                              )
                              : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Post content (NO GestureDetector here)
              Text(
                widget.postContent,
                style: const TextStyle(fontSize: 13),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
              // Post image (if available)
              if (widget.postImage != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      widget.postImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Engagement section
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    VotingBar(
                      type: VotingTargetType.post,
                      postId: widget.postId,
                      initialUpvotes: widget.upvotes,
                      initialDownvotes: widget.downvotes,
                      initialScore: widget.upvotes - widget.downvotes,
                      votingService: VotingService(),
                      initiallyUpvoted: false, // <-- Add this
                      initiallyDownvoted: false, // <-- Add this
                    ),
                    const SizedBox(width: 8),
                    // Comment button section
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _openDetailsPage,
                          icon: const Icon(Icons.chat_bubble_outline),
                          color: Color(0xFF00F6FF),
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                        Text(
                          '${widget.commentCount}',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Share button
                    IconButton(
                      onPressed: _isSharing ? null : _handleShare,
                      icon:
                          _isSharing
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF00F6FF),
                                ),
                              )
                              : const Icon(Icons.share_outlined),
                      color: Color(0xFF00F6FF),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    // Report button
                    IconButton(
                      onPressed: _handleReport,
                      icon: const Icon(Icons.more_horiz),
                      color: Colors.grey[600],
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
