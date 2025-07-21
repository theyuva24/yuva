import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/profile_controller.dart';
import 'models/profile_model.dart';
import 'edit_profile_page.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_actions.dart';
import 'widgets/profile_tabs.dart';
import 'services/profile_service.dart';
import 'settings_page.dart';
import 'package:yuva/universal/theme/app_theme.dart';
import '../../chat/service/chat_service.dart';
import '../../chat/page/chat_page.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  const ProfilePage({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
      final controller = Provider.of<ProfileController>(context, listen: false);
      await controller.loadProfile(widget.uid);
      setState(() {});
    }
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
          final isCurrentUser = profile.uid == widget.uid;
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
                if (isCurrentUser)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.black),
                    onPressed: () => _editProfile(profile),
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
              child: NestedScrollView(
                headerSliverBuilder:
                    (context, innerBoxIsScrolled) => [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProfileHeader(
                              profile: profile,
                              isCurrentUser: isCurrentUser,
                            ),
                            ProfileActions(
                              profile: profile,
                              isCurrentUser: isCurrentUser,
                              onMessage: () => _openChat(profile),
                              onEdit: () => _editProfile(profile),
                            ),
                          ],
                        ),
                      ),
                    ],
                body: ProfileTabs(
                  profile: profile,
                  onBioChanged: (newBio) async {
                    final controller = Provider.of<ProfileController>(
                      context,
                      listen: false,
                    );
                    controller.profile = profile.copyWith(bio: newBio);
                    await controller.saveProfile(widget.uid);
                    await controller.loadProfile(
                      widget.uid,
                      forceRefresh: true,
                    );
                    setState(() {});
                  },
                  onEducationChanged: (
                    college,
                    course,
                    year,
                    educationLevel,
                    idCardUrl,
                  ) async {
                    final controller = Provider.of<ProfileController>(
                      context,
                      listen: false,
                    );
                    controller.profile = profile.copyWith(
                      college: college,
                      course: course,
                      year: year,
                      educationLevel: educationLevel,
                      idCardUrl: idCardUrl,
                    );
                    await controller.saveProfile(widget.uid);
                    await controller.loadProfile(
                      widget.uid,
                      forceRefresh: true,
                    );
                    setState(() {});
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
