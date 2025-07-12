import 'package:flutter/material.dart';
import '../model/submission_model.dart';

class SubmissionCard extends StatelessWidget {
  final Submission submission;
  const SubmissionCard({Key? key, required this.submission}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Image.network(
          submission.mediaUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
        title: Text(submission.caption),
        subtitle: Text('By: \\${submission.userId}'),
      ),
    );
  }
}
