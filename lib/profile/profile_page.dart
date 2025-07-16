import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/profile_controller.dart';
import 'models/profile_model.dart';
import 'edit_profile_page.dart';
import 'widgets/education_info_card.dart';
import '../connect/widget/post_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../chat/service/chat_service.dart';
import '../../chat/page/chat_page.dart';
import '../../core/services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  final String uid;
  const ProfilePage({Key? key, required this.uid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileController()..loadProfile(uid),
      child: Consumer<ProfileController>(
        builder: (context, controller, _) {
          if (controller.isLoading || controller.profile == null) {
            return Scaffold(
              backgroundColor: const Color(0xFF0A0E17),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          final profile = controller.profile!;
          final interests = profile.interests;
          return Scaffold(
            backgroundColor: const Color(0xFF0A0E17),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0A0E17),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        (profile.profilePicUrl.isNotEmpty)
                            ? NetworkImage(profile.profilePicUrl)
                                as ImageProvider
                            : const AssetImage('assets/avatar_placeholder.png'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.fullName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    profile.location,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Builder(
                      builder: (context) {
                        final currentUserId = AuthService().currentUser?.uid;
                        if (currentUserId == profile.uid) {
                          // Show Edit Profile button for owner
                          return ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          EditProfilePage(profile: profile),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF181C23),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text(
                              "Edit Profile",
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        } else {
                          // Show Message button for other users
                          return ElevatedButton.icon(
                            onPressed: () async {
                              final chatService = ChatService();
                              final chat = await chatService
                                  .getOrCreateChatWith(profile.uid);
                              if (!context.mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => ChatPage(
                                        chatId: chat.id,
                                        otherUserId: profile.uid,
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.message,
                              color: Color(0xFF00F6FF),
                            ),
                            label: const Text(
                              "Message",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF00F6FF),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF181C23),
                              foregroundColor: const Color(0xFF00F6FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  DefaultTabController(
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
                          tabs: const [
                            Tab(text: "About Me"),
                            Tab(text: "Posts"),
                          ],
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
                                      "Interests",
                                      style: TextStyle(
                                        color: Color(0xFF00F6FF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      children:
                                          interests
                                              .map(
                                                (interest) => Chip(
                                                  label: Text(
                                                    interest,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  backgroundColor: const Color(
                                                    0xFF181C23,
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      "Education",
                                      style: TextStyle(
                                        color: Color(0xFF00F6FF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: EdgeInsets.only(
                                        left: 0,
                                      ), // Align with Interests
                                      child: EducationInfoCard(
                                        college: profile.college,
                                        course: profile.course,
                                      ),
                                    ),
                                    // Removed Joined and Location sections
                                  ],
                                ),
                              ),
                              // Posts Tab
                              StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection('posts')
                                        .where('userId', isEqualTo: profile.uid)
                                        .orderBy(
                                          'postingTime',
                                          descending: true,
                                        )
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
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
                                          posts[index].data()
                                              as Map<String, dynamic>;
                                      return PostCard(
                                        postId: posts[index].id,
                                        userName: profile.fullName,
                                        userProfileImage: profile.profilePicUrl,
                                        hubName: data['hubName'] ?? '',
                                        hubProfileImage: '',
                                        postContent: data['postContent'] ?? '',
                                        timestamp:
                                            '', // You can format postingTime if needed
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
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
