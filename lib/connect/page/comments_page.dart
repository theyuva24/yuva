import 'package:flutter/material.dart';
import '../post_service.dart';
import '../post_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsPage extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  const CommentsPage({
    Key? key,
    required this.postId,
    required this.postOwnerId,
  }) : super(key: key);

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Column(
        children: [
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
                    return Padding(
                      padding: EdgeInsets.only(
                        left: depth * 16.0,
                        top: 8,
                        bottom: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundImage: NetworkImage(
                                  doc['userProfileImage'] ?? '',
                                ),
                                child:
                                    (doc['userProfileImage'] ?? '').isEmpty
                                        ? const Icon(Icons.person, size: 16)
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
                              Text(_formatTimestamp(doc['commentTime'])),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(doc['commentContent'] ?? ''),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_upward, size: 18),
                                onPressed: () async {
                                  await _postService.voteOnComment(
                                    widget.postId,
                                    commentId,
                                    'upvote',
                                  );
                                },
                              ),
                              Text('${doc['score'] ?? 0}'),
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_downward,
                                  size: 18,
                                ),
                                onPressed: () async {
                                  await _postService.voteOnComment(
                                    widget.postId,
                                    commentId,
                                    'downvote',
                                  );
                                },
                              ),
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text('Reply'),
                                          content: TextField(
                                            controller: _commentController,
                                            decoration: const InputDecoration(
                                              hintText: 'Write a reply...',
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                await _addComment(
                                                  parentCommentId: commentId,
                                                );
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Reply'),
                                            ),
                                          ],
                                        ),
                                  );
                                },
                                child: const Text('Reply'),
                              ),
                            ],
                          ),
                          ...buildComments(commentId, depth + 1),
                        ],
                      ),
                    );
                  }).toList();
                }

                return ListView(
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
}
