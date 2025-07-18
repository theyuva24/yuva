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
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('posts')
                          .where('userId', isEqualTo: profile.uid)
                          .orderBy('postingTime', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No posts yet.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      );
                    }
                    final posts = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final data =
                            posts[index].data() as Map<String, dynamic>;
                        return PostCard(
                          postId: posts[index].id,
                          userName: profile.fullName,
                          userProfileImage: profile.profilePicUrl,
                          hubName: data['hubName'] ?? '',
                          hubProfileImage: '',
                          postContent: data['postContent'] ?? '',
                          timestamp: '',
                          upvotes: data['upvotes'] ?? 0,
                          downvotes: data['downvotes'] ?? 0,
                          commentCount: data['commentCount'] ?? 0,
                          shareCount: data['shareCount'] ?? 0,
                          postImage: data['postImageUrl'],
                          postOwnerId: data['userId'] ?? '',
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
