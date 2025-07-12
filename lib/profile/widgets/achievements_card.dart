import 'package:flutter/material.dart';

class AchievementsCard extends StatelessWidget {
  final List<String> achievements;
  const AchievementsCard({Key? key, required this.achievements})
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
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  achievements.isNotEmpty
                      ? achievements
                          .map((ach) => Chip(label: Text(ach)))
                          .toList()
                      : [Text('No achievements yet')],
            ),
          ],
        ),
      ),
    );
  }
}
