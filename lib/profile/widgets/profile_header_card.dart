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
      backgroundColor: const Color(0xFF181C23),
      child:
          (profileImageUrl.isEmpty || profileImageUrl == 'null')
              ? Icon(Icons.person, size: 40, color: Color(0xFF00F6FF))
              : null,
    );
    avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Color(0xFF00F6FF), width: 3),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF00F6FF).withOpacity(0.5),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: avatar,
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
              backgroundColor: Color(0xFF00F6FF),
              child: Icon(Icons.camera_alt, size: 18, color: Colors.black),
            ),
          ],
        ),
      );
    }
    return Card(
      color: const Color(0xFF181C23),
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF00F6FF), width: 1.5),
      ),
      elevation: 8,
      shadowColor: Color(0xFF00F6FF).withOpacity(0.2),
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
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00F6FF),
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          blurRadius: 12,
                          color: Color(0xFF00F6FF),
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    emailOrPhone,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
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
