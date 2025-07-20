import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import 'education_section.dart';
import 'interests_section.dart';
import '../../connect/widget/post_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../universal/theme/app_theme.dart';

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
                      const Text(
                        "Education",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 12),
                      EducationSection(profile: profile),
                      const SizedBox(height: 28),
                      const Text(
                        "Interests",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InterestsSection(profile: profile),
                    ],
                  ),
                ),
                // Posts Tab
                RefreshIndicator(
                  onRefresh: () async {
                    // Refresh user posts
                    await Future.delayed(const Duration(milliseconds: 800));
                  },
                  color: AppThemeLight.primary,
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('posts')
                            .where('userId', isEqualTo: profile.uid)
                            .orderBy('postingTime', descending: true)
                            .snapshots(),
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
                                  // Trigger refresh by rebuilding
                                  (context as Element).markNeedsBuild();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.post_add_outlined,
                                size: 64,
                                color: AppThemeLight.textLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No posts yet.',
                                style: TextStyle(
                                  color: AppThemeLight.textLight,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start sharing your thoughts!',
                                style: TextStyle(
                                  color: AppThemeLight.textLight,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final posts = snapshot.data!.docs;

                      // Keep chronological order for user posts (no trending score sorting)
                      // Posts are already ordered by postingTime in the stream

                      return ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final data =
                              posts[index].data() as Map<String, dynamic>;
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: PostCard(
                              key: ValueKey(posts[index].id),
                              postId: posts[index].id,
                              userName: profile.fullName,
                              userProfileImage: profile.profilePicUrl,
                              hubName: data['hubName'] ?? '',
                              hubProfileImage: '',
                              postContent: data['postContent'] ?? '',
                              timestamp: _formatTimestamp(data['postingTime']),
                              upvotes: data['upvotes'] ?? 0,
                              downvotes: data['downvotes'] ?? 0,
                              commentCount: data['commentCount'] ?? 0,
                              shareCount: data['shareCount'] ?? 0,
                              postImage: data['postImageUrl'],
                              postOwnerId: data['userId'] ?? '',
                              postType: data['postType'] ?? 'text',
                              linkUrl: data['linkUrl'],
                              pollData: data['pollData'],
                              hubId: data['hubId'] ?? '',
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
