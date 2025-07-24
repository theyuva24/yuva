import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/submission_model.dart';
import '../service/submission_service.dart';
import 'package:yuva/challenge/page/full_screen_media_page.dart';

class SubmissionDetailsPageLoader extends StatelessWidget {
  final String submissionId;
  final String? challengeId;
  const SubmissionDetailsPageLoader({
    required this.submissionId,
    this.challengeId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (challengeId == null) {
      return Scaffold(body: Center(child: Text('Challenge ID required.')));
    }
    final submissionService = SubmissionService();
    return FutureBuilder<List<Submission>>(
      future: submissionService.fetchSubmissionsForChallenge(challengeId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final submissions = snapshot.data!;
        final initialIndex = submissions.indexWhere(
          (s) => s.id == submissionId,
        );
        if (initialIndex == -1) {
          return Scaffold(body: Center(child: Text('Submission not found')));
        }
        return FullScreenMediaPage(
          submissions: submissions,
          initialIndex: initialIndex,
        );
      },
    );
  }
}
