import 'package:flutter/material.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String emailOrPhone;
  final String profileImageUrl;
  final VoidCallback onEdit;
  final bool isEditing;
  final VoidCallback? onImageTap;

  const ProfileHeaderCard({
    Key? key,
    required this.name,
    required this.emailOrPhone,
    required this.profileImageUrl,
    required this.onEdit,
    this.isEditing = false,
    this.onImageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget avatar = CircleAvatar(
      radius: 40,
      backgroundImage:
          (profileImageUrl.isNotEmpty && profileImageUrl != 'null')
              ? NetworkImage(profileImageUrl)
              : null,
      child:
          (profileImageUrl.isEmpty || profileImageUrl == 'null')
              ? Icon(Icons.person, size: 40)
              : null,
    );
    if (isEditing) {
      avatar = GestureDetector(
        onTap: onImageTap,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            avatar,
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white,
              child: Icon(Icons.camera_alt, size: 18, color: Colors.grey[700]),
            ),
          ],
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    emailOrPhone,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
