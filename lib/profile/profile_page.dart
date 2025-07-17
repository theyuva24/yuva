import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/profile_controller.dart';
import 'models/profile_model.dart';
import 'edit_profile_page.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_actions.dart';
import 'widgets/profile_tabs.dart';
import '../connect/widget/post_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../chat/service/chat_service.dart';
import '../../chat/page/chat_page.dart';
import '../initial pages/auth_service.dart';
import 'package:yuva/universal/theme/neon_theme.dart';
import 'package:yuva/universal/theme/gradient_button.dart';
import 'services/profile_service.dart';
import 'settings_page.dart';

// 1. Add a stateful widget wrapper for follow state
class _OtherUserProfileHeader extends StatefulWidget {
  final ProfileModel profile;
  const _OtherUserProfileHeader({required this.profile});
  @override
  State<_OtherUserProfileHeader> createState() =>
      _OtherUserProfileHeaderState();
}

class _OtherUserProfileHeaderState extends State<_OtherUserProfileHeader> {
  bool isFollowing = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
  }

  Future<void> _checkIfFollowing() async {
    final currentUserId = AuthService().currentUser?.uid;
    if (currentUserId == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.profile.uid)
            .get();
    final followers = List<String>.from(doc.data()?['followers'] ?? []);
    setState(() {
      isFollowing = followers.contains(currentUserId);
    });
  }

  Future<void> _toggleFollow() async {
    final currentUserId = AuthService().currentUser?.uid;
    if (currentUserId == null) return;
    setState(() {
      isLoading = true;
    });
    final profileService = ProfileService();
    try {
      if (isFollowing) {
        await profileService.unfollowUser(currentUserId, widget.profile.uid);
      } else {
        await profileService.followUser(currentUserId, widget.profile.uid);
      }
      await _checkIfFollowing();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFollowing ? 'Followed' : 'Unfollowed'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error:  ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        // Profile Picture with Neon Glow
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
                      color: NeonColors.neonCyan.withOpacity(0.7),
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
              color: Colors.white,
            ),
          ),
        ),
        Center(
          child: Text(
            profile.location,
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : _toggleFollow,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: NeonColors.neonCyan, width: 2),
                    foregroundColor: NeonColors.neonCyan,
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
                            "Follow",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: NeonColors.neonCyan,
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GradientButton(
                  onPressed: () async {
                    final chatService = ChatService();
                    final chat = await chatService.getOrCreateChatWith(
                      profile.uid,
                    );
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
                  gradient: NeonGradients.button,
                  child: const Text(
                    "Message",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class ProfilePage extends StatefulWidget {
  final String uid;
  const ProfilePage({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isFollowing = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfFollowing();
  }

  Future<void> _checkIfFollowing() async {
    final currentUserId = AuthService().currentUser?.uid;
    if (currentUserId == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .get();
    final followers = List<String>.from(doc.data()?['followers'] ?? []);
    setState(() {
      isFollowing = followers.contains(currentUserId);
    });
  }

  Future<void> _toggleFollow(ProfileModel profile) async {
    final currentUserId = AuthService().currentUser?.uid;
    if (currentUserId == null) return;
    setState(() {
      isLoading = true;
    });
    final profileService = ProfileService();
    try {
      if (isFollowing) {
        await profileService.unfollowUser(currentUserId, profile.uid);
      } else {
        await profileService.followUser(currentUserId, profile.uid);
      }
      await _checkIfFollowing();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isFollowing ? 'Followed' : 'Unfollowed'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error:   ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  void _openChat(ProfileModel profile) async {
    final chatService = ChatService();
    final chat = await chatService.getOrCreateChatWith(profile.uid);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ChatPage(chatId: chat.id, otherUserId: profile.uid),
      ),
    );
  }

  void _editProfile(ProfileModel profile) async {
    final updatedProfile = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProfilePage(profile: profile),
      ),
    );
    if (updatedProfile != null && mounted) {
      // Reload the profile from the controller
      final controller = Provider.of<ProfileController>(context, listen: false);
      await controller.loadProfile(widget.uid);
      setState(() {}); // This will rebuild the widget with the new data
    }
  }

  void _openFollowers(ProfileModel profile) {
    // TODO: Implement followers list navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Followers list coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileController()..loadProfile(widget.uid),
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
          final currentUserId = AuthService().currentUser?.uid;
          final isCurrentUser = currentUserId == profile.uid;
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
                if (isCurrentUser)
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SettingsPage(profile: profile),
                        ),
                      );
                    },
                  ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  ProfileHeader(profile: profile, isCurrentUser: isCurrentUser),
                  const SizedBox(height: 24),
                  ProfileActions(
                    isCurrentUser: isCurrentUser,
                    profile: profile,
                    isFollowing: isFollowing,
                    isLoading: isLoading,
                    onFollowToggle: () => _toggleFollow(profile),
                    onMessage: () => _openChat(profile),
                    onEdit: () => _editProfile(profile),
                    onFollowers: () => _openFollowers(profile),
                  ),
                  const SizedBox(height: 24),
                  ProfileTabs(profile: profile, interests: interests),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
