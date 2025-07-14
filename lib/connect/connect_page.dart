import 'package:flutter/material.dart';
import 'post_card.dart';
import 'post_model.dart';
import 'post_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hubs/service/hub_service.dart';
import 'post_details_page.dart';

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
  bool _loadingJoinedHubs = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Remove _fetchJoinedHubs();
  }

  Future<void> _fetchJoinedHubs() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final joinedHubs = userDoc.data()?['joinedHubs'] as List<dynamic>? ?? [];
    setState(() {
      _joinedHubs = joinedHubs.map((e) => e.toString()).toList();
      _loadingJoinedHubs = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _calculateTrendingScore(Post post) {
    // Reddit-style: upvotes - downvotes + commentCount + shareCount
    return post.upvotes - post.downvotes + post.commentCount + post.shareCount;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6C63FF),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF6C63FF),
              tabs: const [Tab(text: 'Trending'), Tab(text: 'My Feed')],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Trending Tab
                StreamBuilder<List<Post>>(
                  stream: postService.getPostsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading posts'));
                    }
                    final posts = snapshot.data ?? [];
                    if (posts.isEmpty) {
                      return const Center(child: Text('No posts yet'));
                    }
                    final sortedPosts = List<Post>.from(posts)..sort(
                      (a, b) => _calculateTrendingScore(
                        b,
                      ).compareTo(_calculateTrendingScore(a)),
                    );
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: sortedPosts.length,
                      itemBuilder: (context, index) {
                        final post = sortedPosts[index];
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
                // My Feed Tab (reactive)
                StreamBuilder<List<String>>(
                  stream: _hubService.getJoinedHubsStream(),
                  builder: (context, hubSnapshot) {
                    if (hubSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF),
                        ),
                      );
                    }
                    final joinedHubs = hubSnapshot.data ?? [];
                    return StreamBuilder<List<Post>>(
                      stream: postService.getPostsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF6C63FF),
                            ),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error loading posts'));
                        }
                        final posts =
                            (snapshot.data ?? [])
                                .where(
                                  (post) => joinedHubs.contains(post.hubId),
                                )
                                .toList();
                        if (posts.isEmpty) {
                          return const Center(
                            child: Text('No posts in your feed yet'),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
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
                                          userProfileImage:
                                              post.userProfileImage,
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
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
