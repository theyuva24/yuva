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
import 'package:yuva/universal/theme/app_theme.dart';
import 'services/profile_service.dart';
import 'settings_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        SizedBox(height: 16.h),
        // Profile Picture with Neon Glow
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140.w,
                height: 140.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppThemeLight.primary.withOpacity(0.7),
                      blurRadius: 18.r,
                      spreadRadius: 2.r,
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 60.r,
                backgroundImage:
                    (profile.profilePicUrl.isNotEmpty)
                        ? NetworkImage(profile.profilePicUrl) as ImageProvider
                        : const AssetImage('assets/avatar_placeholder.png'),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Center(
          child: Text(
            profile.fullName,
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Center(
          child: Text(
            profile.location,
            style: TextStyle(fontSize: 18.sp, color: Colors.black54),
          ),
        ),
        SizedBox(height: 24.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : _toggleFollow,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppThemeLight.primary, width: 2.w),
                    foregroundColor: AppThemeLight.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    minimumSize: Size(0, 48.h),
                  ),
                  child:
                      isLoading
                          ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                          : Text(
                            "Follow",
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: AppThemeLight.primary,
                            ),
                          ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: GradientButton(
                  text: "Message",
                  onTap: () async {
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
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
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
              backgroundColor: AppThemeLight.background,
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          final profile = controller.profile!;
          final interests = profile.interests;
          final currentUserId = AuthService().currentUser?.uid;
          final isCurrentUser = currentUserId == profile.uid;
          return Scaffold(
            backgroundColor: AppThemeLight.background,
            appBar: AppBar(
              backgroundColor: AppThemeLight.background,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                if (isCurrentUser)
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.black),
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
            body: RefreshIndicator(
              onRefresh: () async {
                await Provider.of<ProfileController>(
                  context,
                  listen: false,
                ).loadProfile(widget.uid, forceRefresh: true);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    ProfileHeader(
                      profile: profile,
                      isCurrentUser: isCurrentUser,
                    ),
                    ProfileActions(
                      profile: profile,
                      isCurrentUser: isCurrentUser,
                      isFollowing: isFollowing,
                      isLoading: isLoading,
                      onFollowToggle: () => _toggleFollow(profile),
                      onMessage: () => _openChat(profile),
                      onEdit: () => _editProfile(profile),
                      onFollowers: () => _openFollowers(profile),
                    ),
                    ProfileTabs(profile: profile),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
