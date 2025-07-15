import 'package:flutter/material.dart';
import '../widget/post_card.dart';
import '../models/post_model.dart';
import '../service/post_service.dart';
import '../models/hub_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../chat/page/hub_chat_page.dart'; // Import HubChatPage
import '../service/hub_service.dart';
import 'post_details_page.dart'; // Import PostDetailsPage
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: const Color(0xFF181C23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181C23),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00F6FF)),
        title: Text(
          widget.hub.name,
          style: GoogleFonts.orbitron(
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00F6FF),
              letterSpacing: 2,
              shadows: [
                Shadow(
                  blurRadius: 16,
                  color: Color(0xFF00F6FF),
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFF00F6FF), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF00F6FF).withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: NetworkImage(widget.hub.imageUrl),
                    backgroundColor: Color(0xFF181C23),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.hub.name,
                        style: GoogleFonts.orbitron(
                          textStyle: const TextStyle(
                            color: Color(0xFF00F6FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 1,
                            shadows: [
                              Shadow(color: Color(0xFF00F6FF), blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.hub.description,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _loading
                    ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00F6FF),
                    )
                    : ElevatedButton(
                      onPressed: _isJoined ? _leaveHub : _joinHub,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isJoined ? Colors.grey : const Color(0xFF00F6FF),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF00F6FF),
                      ),
                      child: Text(
                        _isJoined ? 'Leave' : 'Join',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                if (_isJoined)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.message, color: Color(0xFF00F6FF)),
                    label: const Text(
                      'Message',
                      style: TextStyle(
                        color: Color(0xFF00F6FF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF232733),
                      foregroundColor: const Color(0xFF00F6FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
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
          const Divider(color: Color(0xFF00F6FF)),
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: postService.getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00F6FF)),
                  );
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading posts',
                      style: TextStyle(color: Color(0xFF00F6FF)),
                    ),
                  );
                }
                final posts =
                    (snapshot.data ?? [])
                        .where((post) => post.hubName == widget.hub.name)
                        .toList();
                if (posts.isEmpty) {
                  return const Center(
                    child: Text(
                      'No posts in this hub yet.',
                      style: TextStyle(color: Color(0xFF00F6FF)),
                    ),
                  );
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
