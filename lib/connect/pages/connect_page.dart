import 'package:flutter/material.dart';
import '../widget/post_card.dart';
import '../models/post_model.dart';
import '../service/post_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../service/hub_service.dart';
import 'post_details_page.dart';
import 'hubs_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../universal/theme/app_theme.dart';
import 'create_post_screen.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PostService postService = PostService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HubService _hubService = HubService();
  List<String> _joinedHubs = [];

  // Caching for optimized performance
  List<Post>? _cachedTrendingPosts;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchJoinedHubs();
  }

  Future<void> _fetchJoinedHubs() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final joinedHubs = userDoc.data()?['joinedHubs'] as List<dynamic>? ?? [];
    setState(() {
      _joinedHubs = joinedHubs.map((e) => e.toString()).toList();
    });
  }

  // Optimized sorting with caching
  List<Post> _getSortedTrendingPosts(List<Post> posts) {
    if (_cachedTrendingPosts == null) {
      _cachedTrendingPosts = List<Post>.from(
        posts,
      )..sort((a, b) => (b.trendingScore ?? 0).compareTo(a.trendingScore ?? 0));
    }
    return _cachedTrendingPosts!;
  }

  List<Post> _getSortedFeedPosts(List<Post> posts, List<String> joinedHubs) {
    final feedPosts =
        posts.where((post) => joinedHubs.contains(post.hubId)).toList();
    // Keep chronological order for My Feed (no trending score sorting)
    return feedPosts;
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
      _cachedTrendingPosts = null;
    });

    // Refresh joined hubs
    await _fetchJoinedHubs();

    // Simulate refresh delay for better UX
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.onSurface,
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.6),
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorWeight: 4.h,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 16,
                  letterSpacing: 1,
                ),
                tabs: const [Tab(text: 'Trending'), Tab(text: 'My Feed')],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Trending Tab with pull-to-refresh and optimized sorting
                  RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: Theme.of(context).colorScheme.primary,
                    child: StreamBuilder<List<Post>>(
                      stream: postService.getPostsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !_isRefreshing) {
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
                                  size: 64.w,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppThemeDark.errorText
                                          : AppThemeLight.errorText,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'Error loading posts',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppThemeDark.textPrimary
                                            : AppThemeLight.textPrimary,
                                    fontSize: 16.sp,
                                  ),
                                ),
                                if (snapshot.error != null) ...[
                                  SizedBox(height: 8.h),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                    ),
                                    child: Text(
                                      snapshot.error.toString(),
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppThemeDark.errorText
                                                : AppThemeLight.errorText,
                                        fontSize: 12.sp,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                                SizedBox(height: 8.h),
                                TextButton(
                                  onPressed: _onRefresh,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }
                        final posts = snapshot.data ?? [];
                        if (posts.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.forum_outlined,
                                  size: 64.w,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppThemeDark.textSecondary
                                          : AppThemeLight.textSecondary,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'No posts yet',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppThemeDark.textSecondary
                                            : AppThemeLight.textSecondary,
                                    fontSize: 16.sp,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Use optimized sorting
                        final sortedPosts = _getSortedTrendingPosts(posts);

                        return ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          itemCount: sortedPosts.length,
                          itemBuilder: (context, index) {
                            final post = sortedPosts[index];
                            return AnimatedSwitcher(
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
                            );
                          },
                        );
                      },
                    ),
                  ),
                  // My Feed Tab with pull-to-refresh and optimized filtering
                  RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: Theme.of(context).colorScheme.primary,
                    child: StreamBuilder<List<String>>(
                      stream: _hubService.getJoinedHubsStream(),
                      builder: (context, hubSnapshot) {
                        if (hubSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppThemeLight.primary,
                            ),
                          );
                        }
                        final joinedHubs = hubSnapshot.data ?? [];
                        return StreamBuilder<List<Post>>(
                          stream: postService.getPostsStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !_isRefreshing) {
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
                                      size: 64.w,
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? AppThemeDark.errorText
                                              : AppThemeLight.errorText,
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      'Error loading feed',
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppThemeDark.textPrimary
                                                : AppThemeLight.textPrimary,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    TextButton(
                                      onPressed: _onRefresh,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              );
                            }
                            final posts = snapshot.data ?? [];

                            // Use optimized filtering and sorting
                            final feedPosts = _getSortedFeedPosts(
                              posts,
                              joinedHubs,
                            );

                            if (feedPosts.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.rss_feed_outlined,
                                      size: 64.w,
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? AppThemeDark.textSecondary
                                              : AppThemeLight.textSecondary,
                                    ),
                                    SizedBox(height: 16.h),
                                    Text(
                                      joinedHubs.isEmpty
                                          ? 'Join some hubs to see posts here'
                                          : 'No posts in your hubs yet',
                                      style: TextStyle(
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppThemeDark.textSecondary
                                                : AppThemeLight.textSecondary,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                    if (joinedHubs.isEmpty) ...[
                                      SizedBox(height: 16.h),
                                      ElevatedButton(
                                        onPressed: () {
                                          // Navigate to hubs page
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => const HubsPage(),
                                            ),
                                          );
                                        },
                                        child: const Text('Explore Hubs'),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 4.h),
                              itemCount: feedPosts.length,
                              itemBuilder: (context, index) {
                                final post = feedPosts[index];
                                return AnimatedSwitcher(
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
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }
}
