import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/submission_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:hive/hive.dart';

const Duration _submissionsCacheDuration = Duration(hours: 1);

class SubmissionService {
  // Get submissions subcollection for a specific challenge
  CollectionReference _getSubmissionsCollection(String challengeId) {
    return FirebaseFirestore.instance
        .collection('challenges')
        .doc(challengeId)
        .collection('challenge_submission');
  }

  Future<List<Submission>> fetchSubmissionsForChallenge(
    String challengeId, {
    bool forceRefresh = false,
  }) async {
    final box = Hive.box('submissions');
    final cacheKey = 'subs_$challengeId';
    final cacheTimeKey = 'subs_time_$challengeId';
    final cacheTime = box.get(cacheTimeKey) as DateTime?;
    final cachedList = box.get(cacheKey) as List?;
    if (!forceRefresh &&
        cachedList != null &&
        cacheTime != null &&
        DateTime.now().difference(cacheTime) < _submissionsCacheDuration) {
      return List<Submission>.from(cachedList.cast<Submission>());
    }
    final snapshot =
        await _getSubmissionsCollection(
          challengeId,
        ).orderBy('timestamp', descending: true).get();
    final submissions =
        snapshot.docs
            .map(
              (doc) => Submission.fromDocument(doc, challengeId: challengeId),
            )
            .toList();
    await box.put(cacheKey, submissions);
    await box.put(cacheTimeKey, DateTime.now());
    return submissions;
  }

  Future<void> addSubmission(Submission submission) async {
    await _getSubmissionsCollection(
      submission.challengeId,
    ).add(submission.toMap());
    // Invalidate cache
    final box = Hive.box('submissions');
    await box.delete('subs_${submission.challengeId}');
    await box.delete('subs_time_${submission.challengeId}');
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
