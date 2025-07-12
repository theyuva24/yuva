import 'package:flutter/material.dart';
import '../model/challenge_model.dart';
import 'submit_entry_page.dart';

class ChallengeDetailsPage extends StatelessWidget {
  final Challenge challenge;
  const ChallengeDetailsPage({Key? key, required this.challenge})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(challenge.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              challenge.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            Text(challenge.description),
            const SizedBox(height: 16),
            Text('Deadline: ${challenge.deadline.toDate()}'),
            const SizedBox(height: 8),
            Text('Prize: ${challenge.prize}'),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubmitEntryPage(challenge: challenge),
                  ),
                );
              },
              child: const Text('Submit Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
