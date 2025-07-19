import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/submission_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class SubmissionService {
  // Get submissions subcollection for a specific challenge
  CollectionReference _getSubmissionsCollection(String challengeId) {
    return FirebaseFirestore.instance
        .collection('challenges')
        .doc(challengeId)
        .collection('challenge_submission');
  }

  Future<List<Submission>> fetchSubmissionsForChallenge(
    String challengeId,
  ) async {
    final snapshot =
        await _getSubmissionsCollection(
          challengeId,
        ).orderBy('timestamp', descending: true).get();
    return snapshot.docs
        .map((doc) => Submission.fromDocument(doc, challengeId: challengeId))
        .toList();
  }

  Future<void> addSubmission(Submission submission) async {
    await _getSubmissionsCollection(
      submission.challengeId,
    ).add(submission.toMap());
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

  Future<String> uploadThumbnail(
    File file,
    String userId,
    String challengeId,
  ) async {
    final ext = file.path.split('.').last;
    final ref = FirebaseStorage.instance
        .ref()
        .child('challenge_thumbnails')
        .child(challengeId)
        .child(userId)
        .child('${DateTime.now().millisecondsSinceEpoch}.$ext');
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask.whenComplete(() {});
    return await snapshot.ref.getDownloadURL();
  }
}
