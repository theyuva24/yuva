import 'package:flutter/material.dart';

class SocialActivityCard extends StatelessWidget {
  final List<String> activities;
  const SocialActivityCard({Key? key, required this.activities})
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
              'Recent Activity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            activities.isNotEmpty
                ? Column(
                  children:
                      activities
                          .map(
                            (activity) => ListTile(
                              leading: Icon(Icons.comment),
                              title: Text(activity),
                            ),
                          )
                          .toList(),
                )
                : Text('No recent activity'),
          ],
        ),
      ),
    );
  }
}
