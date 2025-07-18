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
import '../../universal/theme/app_theme.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        centerTitle: true,
        title: Text(
          widget.hub.name,
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                child: Image.network(
                  widget.hub.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: AppThemeLight.surface,
                elevation: 3,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(0),
                    topRight: Radius.circular(0),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.hub.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppThemeLight.textDark,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.hub.description,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppThemeLight.textLight,
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _loading
                              ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppThemeLight.primary,
                                ),
                              )
                              : ElevatedButton(
                                onPressed: _isJoined ? _leaveHub : _joinHub,
                                child: Text(_isJoined ? 'Leave' : 'Join'),
                              ),
                          if (_isJoined) ...[
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.message,
                                color: AppThemeLight.primary,
                                size: 18,
                              ),
                              label: const Text('Message'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemeLight.surface,
                                foregroundColor: AppThemeLight.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(fontSize: 14),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: Theme.of(context).dividerColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: StreamBuilder<List<Post>>(
                stream: postService.getPostsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppThemeLight.primary,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading posts',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    );
                  }
                  final posts =
                      (snapshot.data ?? [])
                          .where((post) => post.hubName == widget.hub.name)
                          .toList();
                  if (posts.isEmpty) {
                    return Center(
                      child: Text(
                        'No posts in this hub yet.',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    );
                  }
                  return Column(
                    children:
                        posts
                            .map(
                              (post) => PostCard(
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
                                postType: post.postType,
                                linkUrl: post.linkUrl,
                                pollData: post.pollData,
                                onCardTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => PostDetailsPage(
                                            postId: post.id,
                                            userName: post.userName,
                                            userProfileImage:
                                                post.userProfileImage,
                                            hubName: post.hubName,
                                            hubProfileImage:
                                                post.hubProfileImage,
                                            postContent: post.postContent,
                                            timestamp: post.timestamp,
                                            upvotes: post.upvotes,
                                            downvotes: post.downvotes,
                                            commentCount: post.commentCount,
                                            shareCount: post.shareCount,
                                            postImage: post.postImage,
                                            postOwnerId: post.postOwnerId,
                                            postType: post.postType,
                                            linkUrl: post.linkUrl,
                                            pollData: post.pollData,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            )
                            .toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
