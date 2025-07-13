import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/submission_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class SubmissionService {
  final CollectionReference _submissions = FirebaseFirestore.instance
      .collection('challenge_submission');

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

  Future<String> uploadMedia(
    File file,
    String userId,
    String challengeId,
  ) async {
    final ext = file.path.split('.').last;
    final ref = FirebaseStorage.instance
        .ref()
        .child('challenge_media')
        .child(challengeId)
        .child(userId)
        .child('${DateTime.now().millisecondsSinceEpoch}.$ext');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }
}
