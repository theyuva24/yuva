import 'package:flutter/material.dart';
import '../../post_card.dart';
import '../../post_model.dart';
import '../../post_service.dart';
import '../model/hub_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../chat/page/hub_chat_page.dart'; // Import HubChatPage
import '../service/hub_service.dart';
import '../../post/page/post_details_page.dart'; // Import PostDetailsPage

class HubDetailsPage extends StatefulWidget {
  final Hub hub;
  const HubDetailsPage({super.key, required this.hub});

  @override
  State<HubDetailsPage> createState() => _HubDetailsPageState();
}

class _HubDetailsPageState extends State<HubDetailsPage> {
  final PostService postService = PostService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HubService _hubService = HubService();
  bool _isJoined = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkMembership();
  }

  Future<void> _checkMembership() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final joinedHubs = userDoc.data()?['joinedHubs'] as List<dynamic>? ?? [];
    setState(() {
      _isJoined = joinedHubs.contains(widget.hub.id);
      _loading = false;
    });
  }

  Future<void> _joinHub() async {
    setState(() => _loading = true);
    try {
      await _hubService.joinHub(widget.hub.id);
      setState(() {
        _isJoined = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to join hub: $e')));
    } finally {
      setState(() => _loading = false);
      _checkMembership();
    }
  }

  Future<void> _leaveHub() async {
    setState(() => _loading = true);
    try {
      await _hubService.leaveHub(widget.hub.id);
      setState(() {
        _isJoined = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to leave hub: $e')));
    } finally {
      setState(() => _loading = false);
      _checkMembership();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.hub.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(widget.hub.imageUrl),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.hub.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.hub.description),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _loading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : ElevatedButton(
                      onPressed: _isJoined ? _leaveHub : _joinHub,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isJoined ? Colors.grey : const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(_isJoined ? 'Leave' : 'Join'),
                    ),
                ElevatedButton.icon(
                  icon: Icon(Icons.message),
                  label: Text('Message'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder:
                            (context) => HubChatPage(
                              hubId: widget.hub.id,
                              hubName: widget.hub.name,
                            ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: postService.getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading posts'));
                }
                final posts =
                    (snapshot.data ?? [])
                        .where((post) => post.hubName == widget.hub.name)
                        .toList();
                if (posts.isEmpty) {
                  return const Center(child: Text('No posts in this hub yet.'));
                }
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return PostCard(
                      postId: post.id,
                      userName: post.userName,
                      userProfileImage: post.userProfileImage,
                      hubName: post.hubName,
                      hubProfileImage: post.hubProfileImage,
                      postContent: post.postContent,
                      timestamp: post.timestamp,
                      upvotes: post.upvotes,
                      downvotes: post.downvotes,
                      commentCount: post.commentCount,
                      shareCount: post.shareCount,
                      postImage: post.postImage,
                      postOwnerId: post.postOwnerId,
                      onCardTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => PostDetailsPage(
                                  postId: post.id,
                                  userName: post.userName,
                                  userProfileImage: post.userProfileImage,
                                  hubName: post.hubName,
                                  hubProfileImage: post.hubProfileImage,
                                  postContent: post.postContent,
                                  timestamp: post.timestamp,
                                  upvotes: post.upvotes,
                                  downvotes: post.downvotes,
                                  commentCount: post.commentCount,
                                  shareCount: post.shareCount,
                                  postImage: post.postImage,
                                  postOwnerId: post.postOwnerId,
                                ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
