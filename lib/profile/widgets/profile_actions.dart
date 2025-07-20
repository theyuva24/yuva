import 'package:flutter/material.dart';
import '../../universal/theme/app_theme.dart';
import '../models/profile_model.dart';
import '../../chat/page/chat_page.dart';
import '../../chat/service/chat_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileActions extends StatelessWidget {
  final bool isCurrentUser;
  final ProfileModel profile;
  final VoidCallback onMessage;
  final VoidCallback onEdit;

  const ProfileActions({
    Key? key,
    required this.isCurrentUser,
    required this.profile,
    required this.onMessage,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCurrentUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(child: GradientButton(text: "Edit", onTap: onEdit)),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Expanded(child: GradientButton(text: "Message", onTap: onMessage)),
          ],
        ),
      );
    }
  }
}
