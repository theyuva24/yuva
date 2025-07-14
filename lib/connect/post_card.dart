import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'post_service.dart';
import '../profile/profile_page.dart';
import 'hubs/page/hub_details_page.dart';
import 'hubs/model/hub_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_details_page.dart'; // <-- Add this import

// Reddit-style CommentTree widget
class CommentTree extends StatefulWidget {
  final List<Comment> comments;
  final void Function(String parentId)? onReply;
  final void Function(Comment comment, String voteType)? onVote;
  final void Function(Comment comment)? onEdit;
  final void Function(Comment comment)? onDelete;
  final void Function(Comment comment)? onReport;
  final int depth;

  const CommentTree({
    Key? key,
    required this.comments,
    this.onReply,
    this.onVote,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.depth = 0,
  }) : super(key: key);

  @override
  State<CommentTree> createState() => _CommentTreeState();
}

class _CommentTreeState extends State<CommentTree> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          widget.comments
              .map(
                (comment) => CommentCard(
                  comment: comment,
                  depth: widget.depth,
                  onReply: widget.onReply,
                  onVote: widget.onVote,
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                  onReport: widget.onReport,
                ),
              )
              .toList(),
    );
  }
}

class CommentCard extends StatefulWidget {
  final Comment comment;
  final int depth;
  final void Function(String parentId)? onReply;
  final void Function(Comment comment, String voteType)? onVote;
  final void Function(Comment comment)? onEdit;
  final void Function(Comment comment)? onDelete;
  final void Function(Comment comment)? onReport;

  const CommentCard({
    Key? key,
    required this.comment,
    this.depth = 0,
    this.onReply,
    this.onVote,
    this.onEdit,
    this.onDelete,
    this.onReport,
  }) : super(key: key);

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  bool collapsed = false;
  bool showReplyField = false;
  final TextEditingController replyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final isDeleted = comment.deleted;
    final isEdited = comment.edited;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: widget.depth * 16.0),
            Expanded(
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
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
                        Text(
                          comment.content,
                          style: const TextStyle(fontSize: 14),
                        )
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
                          IconButton(
                            icon: Icon(
                              Icons.arrow_upward,
                              color: Colors.grey[700],
                              size: 18,
                            ),
                            onPressed:
                                widget.onVote != null
                                    ? () => widget.onVote!(comment, 'upvote')
                                    : null,
                            tooltip: 'Upvote',
                          ),
                          Text(
                            '${comment.score}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.arrow_downward,
                              color: Colors.grey[700],
                              size: 18,
                            ),
                            onPressed:
                                widget.onVote != null
                                    ? () => widget.onVote!(comment, 'downvote')
                                    : null,
                            tooltip: 'Downvote',
                          ),
                          TextButton(
                            onPressed:
                                isDeleted
                                    ? null
                                    : () => setState(
                                      () => showReplyField = !showReplyField,
                                    ),
                            child: const Text(
                              'Reply',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              collapsed ? Icons.add : Icons.remove,
                              size: 18,
                            ),
                            onPressed:
                                () => setState(() => collapsed = !collapsed),
                            tooltip: collapsed ? 'Expand' : 'Collapse',
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
                                  decoration: const InputDecoration(
                                    hintText: 'Write a reply...',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 8,
                                    ),
                                  ),
                                  minLines: 1,
                                  maxLines: 3,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send, size: 18),
                                onPressed: () {
                                  if (replyController.text.trim().isNotEmpty &&
                                      widget.onReply != null) {
                                    widget.onReply!(comment.id);
                                    replyController.clear();
                                    setState(() => showReplyField = false);
                                  }
                                },
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
        if (!collapsed && comment.replies.isNotEmpty)
          CommentTree(
            comments: comment.replies,
            onReply: widget.onReply,
            onVote: widget.onVote,
            onEdit: widget.onEdit,
            onDelete: widget.onDelete,
            onReport: widget.onReport,
            depth: widget.depth + 1,
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
}

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

  bool _isUpvoted = false;
  bool _isDownvoted = false;
  bool _isVoting = false;
  bool _isSharing = false;
  String? _voteError; // For persistent error feedback
  DateTime? _lastVoteTime; // For debounce

  // Optimistic vote counts - updated immediately for UI
  late int _optimisticUpvotes;
  late int _optimisticDownvotes;
  late int _optimisticScore;

  // Comments state
  List<Comment> _comments = [];
  bool _loadingComments = true;
  String? _commentsError;

  @override
  void initState() {
    super.initState();
    _optimisticUpvotes = widget.upvotes;
    _optimisticDownvotes = widget.downvotes;
    _optimisticScore = widget.upvotes - widget.downvotes;
    _checkUserVote();
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
            final List<Comment> flat = [];
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
                Comment.fromFirestore({
                  ...data,
                  'userName': userName,
                  'userProfileImage': userProfileImage,
                }, doc.id),
              );
            }
            setState(() {
              _comments = buildCommentTree(flat);
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

  Future<void> _checkUserVote() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final voteDoc =
          await _postService.firestore
              .collection('posts')
              .doc(widget.postId)
              .collection('voteInteractions')
              .doc(user.uid)
              .get();

      if (voteDoc.exists) {
        final voteType = voteDoc.data()?['voteType'];
        setState(() {
          _isUpvoted = voteType == 'upvote';
          _isDownvoted = voteType == 'downvote';
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _handleVote(String voteType) async {
    print('[DEBUG] _handleVote called with voteType: ' + voteType);
    // Debounce: ignore if last vote was <500ms ago
    final now = DateTime.now();
    if (_lastVoteTime != null &&
        now.difference(_lastVoteTime!) < const Duration(milliseconds: 500)) {
      print('[DEBUG] Debounced vote');
      return;
    }
    _lastVoteTime = now;
    if (_isVoting) {
      print('[DEBUG] Already voting, skipping');
      return;
    }

    setState(() {
      _isVoting = true;
      _voteError = null;
    });

    // Store previous state for rollback if needed
    final previousUpvoted = _isUpvoted;
    final previousDownvoted = _isDownvoted;
    final previousUpvotes = _optimisticUpvotes;
    final previousDownvotes = _optimisticDownvotes;
    final previousScore = _optimisticScore;

    // Optimistic UI update - immediate response
    setState(() {
      if (voteType == 'upvote') {
        if (_isUpvoted) {
          // Remove upvote
          _isUpvoted = false;
          _optimisticUpvotes--;
          _optimisticScore--;
        } else {
          // Add upvote
          _isUpvoted = true;
          _isDownvoted = false;
          _optimisticUpvotes++;
          if (_isDownvoted) {
            _optimisticDownvotes--;
            _optimisticScore += 2; // Remove downvote + add upvote
          } else {
            _optimisticScore++;
          }
        }
      } else {
        if (_isDownvoted) {
          // Remove downvote
          _isDownvoted = false;
          _optimisticDownvotes--;
          _optimisticScore++;
        } else {
          // Add downvote
          _isDownvoted = true;
          _isUpvoted = false;
          _optimisticDownvotes++;
          if (_isUpvoted) {
            _optimisticUpvotes--;
            _optimisticScore -= 2; // Remove upvote + add downvote
          } else {
            _optimisticScore--;
          }
        }
      }
      _isVoting = false;
    });

    // Firestore operation in background
    try {
      print('[DEBUG] Calling voteOnPost in PostService');
      await _postService.voteOnPost(widget.postId, voteType);
    } catch (e) {
      print('[DEBUG] Exception in _handleVote: ' + e.toString());
      // Rollback optimistic update on error
      setState(() {
        _isUpvoted = previousUpvoted;
        _isDownvoted = previousDownvoted;
        _optimisticUpvotes = previousUpvotes;
        _optimisticDownvotes = previousDownvotes;
        _optimisticScore = previousScore;
        _voteError = 'Failed to vote. Tap to retry.';
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to vote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isVoting = false;
      });
    }
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

  Future<void> _handleCommentVote(Comment comment, String voteType) async {
    try {
      await _postService.voteOnComment(widget.postId, comment.id, voteType);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to vote: $e')));
    }
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
                                    fontSize: 14,
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          label: _isUpvoted ? 'Upvoted' : 'Upvote',
                          selected: _isUpvoted,
                          child: IconButton(
                            onPressed:
                                _isVoting ? null : () => _handleVote('upvote'),
                            icon:
                                _isUpvoted
                                    ? const Icon(
                                      Icons.arrow_upward,
                                      color: Color(0xFF6C63FF),
                                      size: 22,
                                    )
                                    : const Icon(
                                      Icons.arrow_upward_outlined,
                                      color: Colors.grey,
                                      size: 22,
                                    ),
                            tooltip: _isUpvoted ? 'You upvoted' : 'Upvote',
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Text(
                            '$_optimisticScore',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Semantics(
                          label: _isDownvoted ? 'Downvoted' : 'Downvote',
                          selected: _isDownvoted,
                          child: IconButton(
                            onPressed:
                                _isVoting
                                    ? null
                                    : () => _handleVote('downvote'),
                            icon:
                                _isDownvoted
                                    ? const Icon(
                                      Icons.arrow_downward,
                                      color: Color(0xFF6C63FF),
                                      size: 22,
                                    )
                                    : const Icon(
                                      Icons.arrow_downward_outlined,
                                      color: Colors.grey,
                                      size: 22,
                                    ),
                            tooltip:
                                _isDownvoted ? 'You downvoted' : 'Downvote',
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Comment button section
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _openDetailsPage,
                          icon: const Icon(Icons.chat_bubble_outline),
                          color: Colors.grey[600],
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                        Text(
                          '${widget.commentCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
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
                                  color: Color(0xFF6C63FF),
                                ),
                              )
                              : const Icon(Icons.share_outlined),
                      color: Colors.grey[600],
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
                    if (_voteError != null)
                      GestureDetector(
                        onTap:
                            () =>
                                _handleVote(_isUpvoted ? 'upvote' : 'downvote'),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _voteError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
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
