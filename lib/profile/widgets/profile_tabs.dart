import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import 'interests_section.dart';
import '../../connect/widget/post_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../universal/theme/app_theme.dart';
import '../../connect/service/post_service.dart';
import '../../connect/models/post_model.dart';
import '../../connect/pages/post_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileTabs extends StatelessWidget {
  final ProfileModel profile;
  const ProfileTabs({Key? key, required this.profile}) : super(key: key);

  // Format timestamp for display
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    final now = DateTime.now();
    final postTime =
        timestamp is Timestamp
            ? timestamp.toDate()
            : DateTime.parse(timestamp.toString());

    final difference = now.difference(postTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final PostService postService = PostService();
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppThemeLight.background,
            child: const TabBar(
              indicatorColor: AppThemeLight.primary,
              labelColor: AppThemeLight.textDark,
              unselectedLabelColor: AppThemeLight.textLight,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: [Tab(text: "About Me"), Tab(text: "Posts")],
            ),
          ),
          SizedBox(
            height: 500, // Adjust as needed
            child: TabBarView(
              children: [
                // About Me Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (profile.bio.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Text(
                            profile.bio,
                            style: const TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.black87,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Text(
                            'No bio added yet.',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      const Text(
                        "Education",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'College:  ${profile.college}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Course:  ${profile.course}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Year:  ${profile.year}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        "Interests",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      profile.interests.isNotEmpty
                          ? Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children:
                                profile.interests
                                    .map(
                                      (interest) => Chip(
                                        label: Text(
                                          interest,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor: Colors.blue
                                            .withOpacity(0.15),
                                        labelStyle: const TextStyle(
                                          color: Colors.blue,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          side: const BorderSide(
                                            color: Colors.blue,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          )
                          : const Text(
                            'No interests added yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                    ],
                  ),
                ),
                // Posts Tab
                RefreshIndicator(
                  onRefresh: () async {
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
                                style: TextStyle(
                                  color: AppThemeLight.primary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  (context as Element).markNeedsBuild();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      final currentUserId =
                          FirebaseAuth.instance.currentUser?.uid;
                      final userPosts =
                          (snapshot.data ?? [])
                              .where((post) => post.postOwnerId == profile.uid)
                              .where((post) {
                                // Only show anonymous posts to the owner
                                if (profile.uid == currentUserId) {
                                  return true;
                                } else {
                                  return !post.isAnonymous;
                                }
                              })
                              .toList();
                      if (userPosts.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.forum_outlined,
                                size: 64,
                                color: AppThemeLight.textLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No posts yet',
                                style: TextStyle(
                                  color: AppThemeLight.textLight,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: userPosts.length,
                        itemBuilder: (context, index) {
                          final post = userPosts[index];
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
