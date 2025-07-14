import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/profile_controller.dart';
import 'models/profile_model.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_completeness_bar.dart';
import 'widgets/verification_status_card.dart';
import 'widgets/personal_info_card.dart';
import 'widgets/education_info_card.dart';
import 'widgets/interests_card.dart';
// Achievements and SocialActivity cards are omitted for now as not in data
import '../core/services/auth_service.dart';
import '../admin/admin_page.dart';
import '../initial pages/presentation/screens/splash_screen.dart';
import '../chat/page/chat_page.dart'; // Corrected import for ChatPage
import '../chat/service/chat_service.dart'; // Corrected import for ChatService

class ProfilePage extends StatelessWidget {
  final String uid;
  const ProfilePage({Key? key, required this.uid}) : super(key: key);

  double _calculateCompleteness(ProfileModel profile) {
    int total = 9;
    int filled = 0;
    if (profile.fullName.isNotEmpty) filled++;
    if (profile.phone.isNotEmpty) filled++;
    if (profile.profilePicUrl.isNotEmpty) filled++;
    if (profile.dob != null) filled++;
    if (profile.gender.isNotEmpty) filled++;
    if (profile.college.isNotEmpty) filled++;
    if (profile.course.isNotEmpty) filled++;
    if (profile.year.isNotEmpty) filled++;
    if (profile.location.isNotEmpty) filled++;
    return filled / total;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileController()..loadProfile(uid),
      child: Consumer<ProfileController>(
        builder: (context, controller, _) {
          if (controller.isLoading || controller.profile == null) {
            return Scaffold(
              appBar: AppBar(title: Text('Profile')),
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final profile = controller.profile!;
          final completeness = _calculateCompleteness(profile);
          return Scaffold(
            appBar: AppBar(
              title: Text('Profile'),
              actions: [
                if (!controller.isEditing)
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => controller.setEditing(true),
                  ),
                if (controller.isEditing)
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => controller.setEditing(false),
                  ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileHeaderCard(
                    name: controller.isEditing ? '' : profile.fullName,
                    emailOrPhone: controller.isEditing ? '' : profile.phone,
                    profileImageUrl: controller.profilePicUrl ?? '',
                    onEdit: () => controller.setEditing(true),
                    isEditing: controller.isEditing,
                    onImageTap:
                        controller.isEditing
                            ? () => controller.pickProfileImage(uid)
                            : null,
                  ),
                  if (controller.isEditing)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: controller.fullNameController,
                            decoration: InputDecoration(labelText: 'Full Name'),
                          ),
                          TextFormField(
                            controller: controller.phoneController,
                            decoration: InputDecoration(labelText: 'Phone'),
                          ),
                          TextFormField(
                            controller: controller.genderController,
                            decoration: InputDecoration(labelText: 'Gender'),
                          ),
                          Row(
                            children: [
                              Text('DOB: '),
                              Text(
                                controller.dob != null
                                    ? '${controller.dob!.day}/${controller.dob!.month}/${controller.dob!.year}'
                                    : 'Not set',
                              ),
                              TextButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        controller.dob ?? DateTime(2000),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    controller.dob = picked;
                                    controller.notifyListeners();
                                  }
                                },
                                child: Text('Pick'),
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: controller.collegeController,
                            decoration: InputDecoration(labelText: 'College'),
                          ),
                          TextFormField(
                            controller: controller.courseController,
                            decoration: InputDecoration(labelText: 'Course'),
                          ),
                          TextFormField(
                            controller: controller.yearController,
                            decoration: InputDecoration(labelText: 'Year'),
                          ),
                          TextFormField(
                            controller: controller.locationController,
                            decoration: InputDecoration(labelText: 'Location'),
                          ),
                          // TODO: Add interests editing UI
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => controller.saveProfile(uid),
                                  child: Text('Save'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => controller.setEditing(false),
                                  child: Text('Cancel'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (!controller.isEditing) ...[
                    ProfileCompletenessBar(completeness: completeness),
                    VerificationStatusCard(
                      idVerified:
                          profile.idCardUrl != null &&
                          profile.idCardUrl.isNotEmpty,
                      location: profile.location,
                    ),
                    PersonalInfoCard(
                      dob: profile.dob,
                      gender: profile.gender,
                      contact: profile.phone,
                    ),
                    EducationInfoCard(education: _educationString(profile)),
                    InterestsCard(interests: profile.interests),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          if (AuthService().currentUser?.phoneNumber ==
                              '+919876543210')
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.admin_panel_settings),
                                label: Text('Admin'),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => AdminPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if (AuthService().currentUser?.uid != uid)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.message),
                                label: Text('Message'),
                                onPressed: () async {
                                  // Initiate or get chat, then navigate to chat page
                                  final chatService = ChatService();
                                  final chat = await chatService
                                      .getOrCreateChatWith(uid);
                                  if (context.mounted) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (context) => ChatPage(
                                              chatId: chat.id,
                                              otherUserId: uid,
                                            ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ElevatedButton.icon(
                            icon: Icon(Icons.logout),
                            label: Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              // Show confirmation dialog
                              final shouldLogout = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Logout'),
                                    content: Text(
                                      'Are you sure you want to logout?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(
                                              context,
                                            ).pop(false),
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () =>
                                                Navigator.of(context).pop(true),
                                        child: Text('Logout'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (shouldLogout == true) {
                                try {
                                  // Show loading indicator
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  );

                                  // Sign out from Firebase
                                  await AuthService().signOut();

                                  // Close loading dialog
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }

                                  // Navigate to splash screen and clear navigation stack
                                  if (context.mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder:
                                            (context) => const SplashScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                } catch (e) {
                                  // Close loading dialog
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }

                                  // Show error dialog
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Error'),
                                          content: Text(
                                            'Failed to logout. Please try again.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () =>
                                                      Navigator.of(
                                                        context,
                                                      ).pop(),
                                              child: Text('OK'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _educationString(ProfileModel profile) {
    String edu = '';
    if (profile.college.isNotEmpty) edu += profile.college;
    if (profile.course.isNotEmpty)
      edu += (edu.isNotEmpty ? ', ' : '') + profile.course;
    if (profile.year.isNotEmpty)
      edu += (edu.isNotEmpty ? ', ' : '') + profile.year;
    return edu.isNotEmpty ? edu : 'Not set';
  }
}
