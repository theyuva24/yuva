import 'package:flutter/material.dart';

class ProfileCompletenessBar extends StatelessWidget {
  final double completeness;
  const ProfileCompletenessBar({Key? key, required this.completeness})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile Completeness: ${(completeness * 100).toInt()}%'),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: completeness),
        ],
      ),
    );
  }
}
