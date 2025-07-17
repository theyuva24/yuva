import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import 'package:yuva/universal/theme/neon_theme.dart';
import 'package:yuva/universal/theme/gradient_button.dart';

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
                  side: BorderSide(color: NeonColors.neonCyan, width: 2),
                  foregroundColor: NeonColors.neonCyan,
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
                    color: NeonColors.neonCyan,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GradientButton(
                onPressed: onEdit,
                gradient: NeonGradients.button,
                child: const Text(
                  "Edit",
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
                        : Text(
                          isFollowing ? "Following" : "Follow",
                          style: const TextStyle(
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
                onPressed: onMessage,
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
      );
    }
  }
}
