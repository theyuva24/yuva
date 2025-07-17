import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import 'package:yuva/universal/theme/neon_theme.dart';

class EducationSection extends StatelessWidget {
  final ProfileModel profile;
  const EducationSection({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF181C23),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: const Icon(Icons.school, color: NeonColors.neonCyan, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            profile.college +
                (profile.course.isNotEmpty ? ", ${profile.course}" : ""),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
