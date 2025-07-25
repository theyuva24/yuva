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
import 'package:cached_network_image/cached_network_image.dart';

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                // Hub image at natural size, centered, scaled down to fit width
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: CachedNetworkImage(
                      imageUrl: widget.hub.imageUrl,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                                size: 48,
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
                // Back button and title overlay (positioned over image)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 26,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Theme.of(
                                context,
                              ).shadowColor.withOpacity(0.1),
                            ),
                          ],
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 22,
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withAlpha(128),
                      ),
                      // Removed hub name overlay here
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
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
                      color: AppThemeLight.textPrimary,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.hub.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppThemeLight.textSecondary,
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
                          : _isJoined
                          ? Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                          )
                          : ElevatedButton(
                            onPressed: _isJoined ? _leaveHub : _joinHub,
                            child: Text(_isJoined ? 'Leave' : 'Join'),
                          ),
                      if (_isJoined) ...[
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: Icon(
                            Icons.message,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                          label: const Text('Message'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
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
            const SizedBox(height: 8),
            Divider(color: Theme.of(context).dividerColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: RefreshIndicator(
                onRefresh: () async {
                  // Refresh posts for this hub
                  await Future.delayed(const Duration(milliseconds: 800));
                },
                color: AppThemeLight.primary,
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppThemeLight.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading posts',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: AppThemeLight.primary),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                // Trigger refresh
                                setState(() {});
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                    final posts =
                        (snapshot.data ?? [])
                            .where((post) => post.hubId == widget.hub.id)
                            .toList();

                    // Keep chronological order for hub posts (no trending score sorting)
                    // Posts are already ordered by postingTime in the stream

                    if (posts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.forum_outlined,
                              size: 64,
                              color: AppThemeLight.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No posts in this hub yet.',
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                color: AppThemeLight.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to share something!',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: AppThemeLight.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children:
                          posts
                              .map(
                                (post) => AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: PostCard(
                                    key: ValueKey(post.id),
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
                                    hubId: post.hubId,
                                  ),
                                ),
                              )
                              .toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
