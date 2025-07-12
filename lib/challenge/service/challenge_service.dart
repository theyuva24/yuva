import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/challenge_model.dart';

class ChallengeService {
  final CollectionReference _challenges = FirebaseFirestore.instance.collection(
    'challenges',
  );

  Future<List<Challenge>> fetchAllChallenges() async {
    final snapshot =
        await _challenges.orderBy('deadline', descending: false).get();
    return snapshot.docs.map((doc) => Challenge.fromDocument(doc)).toList();
  }

  Future<Challenge?> fetchChallengeById(String id) async {
    final doc = await _challenges.doc(id).get();
    if (doc.exists) {
      return Challenge.fromDocument(doc);
    }
    return null;
  }

  Future<void> addChallenge(Challenge challenge) async {
    await _challenges.add(challenge.toMap());
  }
}
