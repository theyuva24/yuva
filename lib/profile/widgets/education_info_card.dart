import 'package:flutter/material.dart';

class EducationInfoCard extends StatelessWidget {
  final String education;
  const EducationInfoCard({Key? key, required this.education})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Education', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.school),
              title: Text(education.isNotEmpty ? education : 'Not set'),
            ),
          ],
        ),
      ),
    );
  }
}
