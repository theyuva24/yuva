import 'package:flutter/material.dart';

class EducationInfoCard extends StatelessWidget {
  final String education;
  const EducationInfoCard({Key? key, required this.education})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF181C23),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFF00F6FF), width: 1.5),
      ),
      elevation: 6,
      shadowColor: Color(0xFF00F6FF).withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Education',
              style: TextStyle(
                color: Color(0xFF00F6FF),
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.1,
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: Color(0xFF00F6FF),
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              education,
              style: TextStyle(
                color: Color(0xFF00F6FF),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
