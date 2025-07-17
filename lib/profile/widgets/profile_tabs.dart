import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import 'education_section.dart';
import 'interests_section.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../connect/widget/post_card.dart';

class ProfileTabs extends StatelessWidget {
  final ProfileModel profile;
  final List<String> interests;
  const ProfileTabs({Key? key, required this.profile, required this.interests})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            indicatorColor: const Color(0xFF00F6FF),
            labelColor: const Color(0xFF00F6FF),
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              shadows: [
                Shadow(
                  blurRadius: 8,
                  color: Color(0xFF00F6FF),
                  offset: Offset(0, 0),
                ),
              ],
            ),
            indicatorWeight: 3,
            tabs: const [Tab(text: "About Me"), Tab(text: "Posts")],
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
                          color: Colors.white,
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
                          color: Colors.white,
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
                          style: TextStyle(color: Colors.white70),
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
