import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'post_service.dart';
import 'hubs/model/hub_model.dart';
import 'hubs/page/hub_details_page.dart';
import 'page/comments_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

// Bottom sheet for comments (Reddit style)
class PostCommentsBottomSheet extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  const PostCommentsBottomSheet({
    Key? key,
    required this.postId,
    required this.postOwnerId,
  }) : super(key: key);

  @override
  State<PostCommentsBottomSheet> createState() =>
      _PostCommentsBottomSheetState();
}

class _PostCommentsBottomSheetState extends State<PostCommentsBottomSheet> {
  final PostService _postService = PostService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment({String? parentCommentId}) async {
    if (_commentController.text.trim().isEmpty) return;
    await _postService.addComment(
      widget.postId,
      _commentController.text.trim(),
      parentCommentId: parentCommentId,
    );
    _commentController.clear();
    setState(() {});
  }

  // Add color palette for nesting bars
  static const List<Color> _nestingColors = [
    Color(0xFFff4500), // Reddit orange
    Color(0xFF46a1ff), // Blue
    Color(0xFF46d160), // Green
    Color(0xFFb36aff), // Purple
    Color(0xFFffb347), // Yellow
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('posts')
                          .doc(widget.postId)
                          .collection('comments')
                          .orderBy('commentTime', descending: false)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No comments yet.'));
                    }
                    final comments = snapshot.data!.docs;
                    // Build a map of parentId -> list of replies
                    Map<String?, List<QueryDocumentSnapshot>> replies = {};
                    for (var doc in comments) {
                      final parentId = doc['parentCommentId'];
                      replies.putIfAbsent(parentId, () => []).add(doc);
                    }
                    // Recursive builder
                    List<Widget> buildComments(String? parentId, int depth) {
                      return (replies[parentId] ?? []).map((doc) {
                        final commentId = doc.id;
                        final hasReplies =
                            (replies[commentId]?.isNotEmpty ?? false);
                        final isCollapsed = _collapsedComments.contains(
                          commentId,
                        );
                        final nestingColor =
                            _nestingColors[depth % _nestingColors.length];
                        final data = doc.data() as Map<String, dynamic>?;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Colored nesting bar
                            if (depth > 0)
                              Container(
                                width: 4,
                                height: isCollapsed ? 36 : null,
                                margin: EdgeInsets.only(
                                  right: 8,
                                  left: max(0, depth - 1) * 2.0,
                                ),
                                decoration: BoxDecoration(
                                  color: nestingColor.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundImage:
                                              (data != null &&
                                                      data.containsKey(
                                                        'userProfileImage',
                                                      ) &&
                                                      (doc['userProfileImage'] ??
                                                              '')
                                                          .isNotEmpty)
                                                  ? NetworkImage(
                                                    doc['userProfileImage'],
                                                  )
                                                  : null,
                                          child:
                                              (data == null ||
                                                      !data.containsKey(
                                                        'userProfileImage',
                                                      ) ||
                                                      (doc['userProfileImage'] ??
                                                              '')
                                                          .isEmpty)
                                                  ? const Icon(
                                                    Icons.person,
                                                    size: 16,
                                                  )
                                                  : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          doc['userName'] ?? 'Anonymous User',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatTimestamp(doc['commentTime']),
                                        ),
                                        const Spacer(),
                                        if (hasReplies)
                                          IconButton(
                                            icon: Icon(
                                              isCollapsed
                                                  ? Icons.chevron_right
                                                  : Icons.expand_more,
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (isCollapsed) {
                                                  _collapsedComments.remove(
                                                    commentId,
                                                  );
                                                } else {
                                                  _collapsedComments.add(
                                                    commentId,
                                                  );
                                                }
                                              });
                                            },
                                            tooltip:
                                                isCollapsed
                                                    ? 'Expand replies'
                                                    : 'Collapse replies',
                                          ),
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            // TODO: Implement actions (edit, delete, report, copy link)
                                          },
                                          itemBuilder:
                                              (context) => [
                                                if (doc['userId'] ==
                                                    _auth.currentUser?.uid)
                                                  const PopupMenuItem(
                                                    value: 'edit',
                                                    child: Text('Edit'),
                                                  ),
                                                if (doc['userId'] ==
                                                    _auth.currentUser?.uid)
                                                  const PopupMenuItem(
                                                    value: 'delete',
                                                    child: Text('Delete'),
                                                  ),
                                                const PopupMenuItem(
                                                  value: 'report',
                                                  child: Text('Report'),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'copy',
                                                  child: Text('Copy Link'),
                                                ),
                                              ],
                                          icon: const Icon(
                                            Icons.more_vert,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Reddit-style vertical upvote/downvote
                                        Column(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.arrow_upward,
                                                color:
                                                    _userVote(commentId) ==
                                                            'upvote'
                                                        ? Colors.orange
                                                        : Colors.grey,
                                                size: 20,
                                              ),
                                              onPressed: () async {
                                                await _postService
                                                    .voteOnComment(
                                                      widget.postId,
                                                      commentId,
                                                      'upvote',
                                                    );
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                minWidth: 32,
                                                minHeight: 32,
                                              ),
                                            ),
                                            Text(
                                              '${doc['score'] ?? 0}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _scoreColor(
                                                  doc['score'] ?? 0,
                                                  commentId,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.arrow_downward,
                                                color:
                                                    _userVote(commentId) ==
                                                            'downvote'
                                                        ? Colors.blue
                                                        : Colors.grey,
                                                size: 20,
                                              ),
                                              onPressed: () async {
                                                await _postService
                                                    .voteOnComment(
                                                      widget.postId,
                                                      commentId,
                                                      'downvote',
                                                    );
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                minWidth: 32,
                                                minHeight: 32,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (isCollapsed)
                                                Text(
                                                  'Replies hidden (${replies[commentId]?.length ?? 0})',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              if (!isCollapsed) ...[
                                                Text(
                                                  doc['commentContent'] ?? '',
                                                ),
                                                Row(
                                                  children: [
                                                    TextButton(
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder:
                                                              (
                                                                context,
                                                              ) => AlertDialog(
                                                                title:
                                                                    const Text(
                                                                      'Reply',
                                                                    ),
                                                                content: TextField(
                                                                  controller:
                                                                      _commentController,
                                                                  decoration:
                                                                      const InputDecoration(
                                                                        hintText:
                                                                            'Write a reply...',
                                                                      ),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed:
                                                                        () => Navigator.pop(
                                                                          context,
                                                                        ),
                                                                    child: const Text(
                                                                      'Cancel',
                                                                    ),
                                                                  ),
                                                                  ElevatedButton(
                                                                    onPressed: () async {
                                                                      await _addComment(
                                                                        parentCommentId:
                                                                            commentId,
                                                                      );
                                                                      Navigator.pop(
                                                                        context,
                                                                      );
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                          'Reply',
                                                                        ),
                                                                  ),
                                                                ],
                                                              ),
                                                        );
                                                      },
                                                      child: const Text(
                                                        'Reply',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                ...buildComments(
                                                  commentId,
                                                  min(depth + 1, 4),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    }

                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      children: buildComments(null, 0),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _addComment(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  // Add state for collapsed comments and user votes
  Set<String> _collapsedComments = {};
  Map<String, String> _commentVotes = {};

  // Helper to get user vote for a comment
  String? _userVote(String commentId) => _commentVotes[commentId];

  // Helper to color score
  Color _scoreColor(int score, String commentId) {
    if (_userVote(commentId) == 'upvote') return Colors.orange;
    if (_userVote(commentId) == 'downvote') return Colors.blue;
    return Colors.grey[800]!;
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

  int _upvotes = 0;
  int _downvotes = 0;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _fetchVoteState();
  }

  Future<void> _fetchVoteState() async {
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
      } else {
        setState(() {
          _isUpvoted = false;
          _isDownvoted = false;
        });
      }
      // Fetch latest post counts
      final postDoc =
          await _postService.firestore
              .collection('posts')
              .doc(widget.postId)
              .get();
      if (postDoc.exists) {
        setState(() {
          _upvotes = postDoc.data()?['upvotes'] ?? 0;
          _downvotes = postDoc.data()?['downvotes'] ?? 0;
          _score = postDoc.data()?['score'] ?? 0;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _handleVote(String voteType) async {
    if (_isVoting) return;
    setState(() {
      _isVoting = true;
    });

    // Store previous state for rollback if needed
    final prevUpvoted = _isUpvoted;
    final prevDownvoted = _isDownvoted;
    final prevScore = _score;

    // Optimistically update UI
    setState(() {
      if (voteType == 'upvote') {
        if (_isUpvoted) {
          _isUpvoted = false;
          _score -= 1;
        } else {
          _isUpvoted = true;
          if (_isDownvoted) {
            _isDownvoted = false;
            _score += 2;
          } else {
            _score += 1;
          }
        }
      } else if (voteType == 'downvote') {
        if (_isDownvoted) {
          _isDownvoted = false;
          _score += 1;
        } else {
          _isDownvoted = true;
          if (_isUpvoted) {
            _isUpvoted = false;
            _score -= 2;
          } else {
            _score -= 1;
          }
        }
      }
    });

    try {
      await _postService.voteOnPost(widget.postId, voteType);
      await _fetchVoteState();
    } catch (e) {
      // Revert UI on error
      setState(() {
        _isUpvoted = prevUpvoted;
        _isDownvoted = prevDownvoted;
        _score = prevScore;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to vote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => UserProfilePlaceholderPage(
                                    userId: widget.postOwnerId,
                                  ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(
                            widget.userProfileImage,
                          ),
                          onBackgroundImageError: (exception, stackTrace) {
                            // Fallback to default avatar
                          },
                          child:
                              widget.userProfileImage.isEmpty
                                  ? const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 20,
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => UserProfilePlaceholderPage(
                                          userId: widget.postOwnerId,
                                        ),
                                  ),
                                );
                              },
                              child: Text(
                                widget.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
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
                                        .hubName, // fallback if id not available
                                name: widget.hubName,
                                description:
                                    '', // No description in post, so leave blank
                                imageUrl: widget.hubProfileImage,
                              ),
                            ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(widget.hubProfileImage),
                    onBackgroundImageError: (exception, stackTrace) {
                      // Fallback to default hub icon
                    },
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

            // Post content
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
            Row(
              children: [
                // Voting buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      scale: _isUpvoted ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: IconButton(
                        onPressed:
                            _isVoting ? null : () => _handleVote('upvote'),
                        icon: Icon(
                          Icons.keyboard_arrow_up,
                          color:
                              _isUpvoted
                                  ? const Color(0xFF6C63FF)
                                  : Colors.grey[600],
                        ),
                        iconSize: 24,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                    Text(
                      '$_score',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    AnimatedScale(
                      scale: _isDownvoted ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: IconButton(
                        onPressed:
                            _isVoting ? null : () => _handleVote('downvote'),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: _isDownvoted ? Colors.red : Colors.grey[600],
                        ),
                        iconSize: 24,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Comment button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder:
                              (context) => PostCommentsBottomSheet(
                                postId: widget.postId,
                                postOwnerId: widget.postOwnerId,
                              ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      color: Colors.grey[600],
                      iconSize: 18,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                    Text(
                      '${widget.commentCount}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(width: 12),

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
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),

                const Spacer(),

                // Report button
                IconButton(
                  onPressed: _handleReport,
                  icon: const Icon(Icons.more_horiz),
                  color: Colors.grey[600],
                  iconSize: 18,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Add placeholder pages for navigation
class UserProfilePlaceholderPage extends StatelessWidget {
  final String userId;
  const UserProfilePlaceholderPage({Key? key, required this.userId})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Center(child: Text('User profile for: ' + userId)),
    );
  }
}

class HubDetailsPlaceholderPage extends StatelessWidget {
  final String hubName;
  const HubDetailsPlaceholderPage({Key? key, required this.hubName})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hub Details')),
      body: Center(child: Text('Hub details for: ' + hubName)),
    );
  }
}
