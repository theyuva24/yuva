import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/submission_model.dart';

class SubmissionService {
  final CollectionReference _submissions = FirebaseFirestore.instance
      .collection('submissions');

  Future<List<Submission>> fetchSubmissionsForChallenge(
    String challengeId,
  ) async {
    final snapshot =
        await _submissions
            .where('challengeId', isEqualTo: challengeId)
            .orderBy('timestamp', descending: true)
            .get();
    return snapshot.docs.map((doc) => Submission.fromDocument(doc)).toList();
  }

  Future<void> addSubmission(Submission submission) async {
    await _submissions.add(submission.toMap());
  }
}
