import 'package:flutter/material.dart';
import '../../universal/theme/app_theme.dart';

class EducationInfoCard extends StatelessWidget {
  final String college;
  final String course;
  final String year;
  const EducationInfoCard({
    Key? key,
    required this.college,
    required this.course,
    required this.year,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppThemeLight.surface,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppThemeLight.primary, width: 1.5),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'College',
              style: TextStyle(
                color: AppThemeLight.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              college,
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              'Course',
              style: TextStyle(
                color: AppThemeLight.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              course,
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              'Year',
              style: TextStyle(
                color: AppThemeLight.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              year,
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
