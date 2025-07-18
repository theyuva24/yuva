import 'package:flutter/material.dart';
import '../../universal/theme/app_theme.dart';
import '../models/profile_model.dart';
import '../../chat/page/chat_page.dart';
import '../../chat/service/chat_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileActions extends StatelessWidget {
  final bool isCurrentUser;
  final ProfileModel profile;
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback onFollowToggle;
  final VoidCallback onMessage;
  final VoidCallback onEdit;
  final VoidCallback onFollowers;

  const ProfileActions({
    Key? key,
    required this.isCurrentUser,
    required this.profile,
    this.isFollowing = false,
    this.isLoading = false,
    required this.onFollowToggle,
    required this.onMessage,
    required this.onEdit,
    required this.onFollowers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCurrentUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onFollowers,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppThemeLight.primary, width: 2),
                  foregroundColor: AppThemeLight.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  minimumSize: const Size(0, 48),
                ),
                child: const Text(
                  "Follower",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppThemeLight.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: GradientButton(text: "Edit", onTap: onEdit)),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading ? null : onFollowToggle,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppThemeLight.primary, width: 2),
                  foregroundColor: AppThemeLight.primary,
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
                        : Text(
                          isFollowing ? "Following" : "Follow",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppThemeLight.primary,
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: GradientButton(text: "Message", onTap: onMessage)),
          ],
        ),
      );
    }
  }
}
