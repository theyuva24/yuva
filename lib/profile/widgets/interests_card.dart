import 'package:flutter/material.dart';

class InterestsCard extends StatelessWidget {
  final List<String> interests;
  const InterestsCard({Key? key, required this.interests}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Interests', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  interests.isNotEmpty
                      ? interests
                          .map((interest) => Chip(label: Text(interest)))
                          .toList()
                      : [Text('No interests set')],
            ),
          ],
        ),
      ),
    );
  }
}
