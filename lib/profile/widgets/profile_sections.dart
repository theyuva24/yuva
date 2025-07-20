import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import 'package:yuva/universal/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../connect/widget/post_card.dart';
import '../../connect/service/post_service.dart';
import '../../connect/models/post_model.dart';
import '../../connect/pages/post_details_page.dart';

// ------------------- ProfileHeader -------------------
class ProfileHeader extends StatelessWidget {
  final ProfileModel profile;
  final bool isCurrentUser;
  const ProfileHeader({
    Key? key,
    required this.profile,
    required this.isCurrentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppThemeLight.primary.withOpacity(0.7),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 60,
                backgroundImage:
                    (profile.profilePicUrl.isNotEmpty)
                        ? NetworkImage(profile.profilePicUrl) as ImageProvider
                        : const AssetImage('assets/avatar_placeholder.png'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            profile.fullName,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Center(
          child: Text(
            profile.location,
            style: const TextStyle(fontSize: 18, color: Colors.black54),
          ),
        ),
      ],
    );
  }
}

// ------------------- ProfileActions -------------------
class ProfileActions extends StatelessWidget {
  final bool isCurrentUser;
  final ProfileModel profile;
  final bool isLoading;
  final VoidCallback onMessage;
  final VoidCallback onEdit;

  const ProfileActions({
    Key? key,
    required this.isCurrentUser,
    required this.profile,
    this.isLoading = false,
    required this.onMessage,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCurrentUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppThemeLight.primary, width: 2),
                  foregroundColor: AppThemeLight.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text(
                  "Edit",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppThemeLight.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: GradientButton(text: "Message", onTap: onMessage)),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : onMessage,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppThemeLight.primary, width: 2),
                  foregroundColor: AppThemeLight.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size(0, 48),
                ),
                child:
                    isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text(
                          "Message",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppThemeLight.primary,
                          ),
                        ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

// ------------------- EducationSection (merged) -------------------
class EducationSection extends StatelessWidget {
  final ProfileModel profile;
  const EducationSection({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppThemeLight.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: const Icon(
            Icons.school,
            color: AppThemeLight.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.college,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (profile.course.isNotEmpty)
                Text(
                  profile.course,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------- InterestsSection (merged) -------------------
class InterestsSection extends StatelessWidget {
  final List<String> interests;
  const InterestsSection({Key? key, required this.interests}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children:
          interests
              .map(
                (interest) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppThemeLight.primary,
                      width: 1.5,
                    ),
                    color: Colors.transparent,
                  ),
                  child: Text(
                    interest,
                    style: const TextStyle(
                      color: AppThemeLight.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}

// ------------------- ProfileTabs -------------------
class ProfileTabs extends StatelessWidget {
  final ProfileModel profile;
  final List<String> interests;
  const ProfileTabs({Key? key, required this.profile, required this.interests})
    : super(key: key);

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
    final PostService _postService = PostService();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: AppThemeLight.background,
              child: TabBar(
                overlayColor: MaterialStateProperty.all(AppThemeLight.surface),
                indicatorColor: AppThemeLight.primary,
                labelColor: AppThemeLight.textDark,
                unselectedLabelColor: AppThemeLight.textLight,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                tabs: const [Tab(text: "About Me"), Tab(text: "Posts")],
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
                        InterestsSection(interests: interests),
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
                      stream: _postService.getPostsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                        final userPosts =
                            (snapshot.data ?? [])
                                .where(
                                  (post) => post.postOwnerId == profile.uid,
                                )
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
