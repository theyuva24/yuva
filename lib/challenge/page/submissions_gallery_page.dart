import 'package:flutter/material.dart';
import '../model/challenge_model.dart';
import '../service/submission_service.dart';
import '../widget/submission_card.dart';
import '../model/submission_model.dart';

class SubmissionsGalleryPage extends StatefulWidget {
  final Challenge challenge;
  const SubmissionsGalleryPage({Key? key, required this.challenge})
    : super(key: key);

  @override
  State<SubmissionsGalleryPage> createState() => _SubmissionsGalleryPageState();
}

class _SubmissionsGalleryPageState extends State<SubmissionsGalleryPage> {
  final SubmissionService _submissionService = SubmissionService();
  late Future<List<Submission>> _submissionsFuture;

  @override
  void initState() {
    super.initState();
    _submissionsFuture = _submissionService.fetchSubmissionsForChallenge(
      widget.challenge.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submissions')),
      body: FutureBuilder<List<Submission>>(
        future: _submissionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final submissions = snapshot.data ?? [];
          if (submissions.isEmpty) {
            return const Center(child: Text('No submissions yet.'));
          }
          return ListView.builder(
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              return SubmissionCard(submission: submissions[index]);
            },
          );
        },
      ),
    );
  }
}
