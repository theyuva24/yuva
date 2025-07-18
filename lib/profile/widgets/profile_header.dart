import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../../universal/theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      ],
    );
  }
}
