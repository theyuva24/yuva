import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/profile_controller.dart';
import 'models/profile_model.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_actions.dart';
import 'widgets/profile_tabs.dart';
import 'settings_page.dart';
import 'package:yuva/universal/theme/app_theme.dart';
import '../../chat/service/chat_service.dart';
import '../../chat/page/chat_page.dart';

class OwnerProfilePage extends StatefulWidget {
  final String uid;
  const OwnerProfilePage({super.key, required this.uid});

  @override
  State<OwnerProfilePage> createState() => _OwnerProfilePageState();
}

class _OwnerProfilePageState extends State<OwnerProfilePage> {
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
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                if (isCurrentUser)
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
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
                            ),
                          ],
                        ),
                      ),
                    ],
                body: ProfileTabs(
                  profile: profile,
                  isPublic: false,
                  onBioChanged: (newBio) async {
                    final controller = Provider.of<ProfileController>(
                      context,
                      listen: false,
                    );
                    controller.profile = profile.copyWith(bio: newBio);
                    controller.updateControllersFromProfile(
                      controller.profile!,
                    );
                    await controller.saveProfile(widget.uid);
                    await controller.loadProfile(
                      widget.uid,
                      forceRefresh: true,
                    );
                    setState(() {});
                  },
                  onEducationChanged: (
                    educationList,
                    educationLevel,
                    college,
                    course,
                    year,
                    idCardUrl,
                  ) async {
                    final controller = Provider.of<ProfileController>(
                      context,
                      listen: false,
                    );
                    controller.profile = profile.copyWith(
                      education: educationList,
                      educationLevel: educationLevel,
                      college: college,
                      course: course,
                      year: year,
                      idCardUrl: idCardUrl ?? '',
                    );
                    controller.updateControllersFromProfile(
                      controller.profile!,
                    );
                    await controller.saveProfile(
                      widget.uid,
                      education: educationList,
                    );
                    await controller.loadProfile(
                      widget.uid,
                      forceRefresh: true,
                    );
                    setState(() {});
                  },
                  onInterestsChanged: (interestsList) async {
                    final controller = Provider.of<ProfileController>(
                      context,
                      listen: false,
                    );
                    controller.profile = profile.copyWith(
                      interests: interestsList,
                    );
                    controller.updateControllersFromProfile(
                      controller.profile!,
                    );
                    await controller.saveProfile(widget.uid);
                    await controller.loadProfile(
                      widget.uid,
                      forceRefresh: true,
                    );
                    setState(() {});
                  },
                  onPersonalInfoChanged: (updatedProfile) async {
                    final controller = Provider.of<ProfileController>(
                      context,
                      listen: false,
                    );
                    controller.profile = updatedProfile;
                    controller.updateControllersFromProfile(
                      controller.profile!,
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
