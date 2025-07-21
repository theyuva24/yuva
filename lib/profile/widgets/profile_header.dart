import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../../universal/theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/profile_controller.dart';

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
        SizedBox(height: 16.h),
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
                      color: AppThemeLight.primary.withAlpha(179),
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
              if (isCurrentUser)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) return;
                      final controller = Provider.of<ProfileController>(
                        context,
                        listen: false,
                      );
                      await controller.pickProfileImage(uid);
                      await controller.saveProfile(uid);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 2),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 26,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ),
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
      ],
    );
  }
}
