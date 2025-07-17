import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/challenge_model.dart';

List<Challenge>? _cachedChallenges;
DateTime? _challengesCacheTime;
const Duration _challengesCacheDuration = Duration(minutes: 5);

void clearChallengesCache() {
  _cachedChallenges = null;
  _challengesCacheTime = null;
}

class ChallengeService {
  final CollectionReference _challenges = FirebaseFirestore.instance.collection(
    'challenges',
  );

  Future<List<Challenge>> fetchAllChallenges({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedChallenges != null &&
        _challengesCacheTime != null &&
        DateTime.now().difference(_challengesCacheTime!) <
            _challengesCacheDuration) {
      return _cachedChallenges!;
    }
    final snapshot =
        await _challenges.orderBy('deadline', descending: false).get();
    final challenges =
        snapshot.docs.map((doc) => Challenge.fromDocument(doc)).toList();
    _cachedChallenges = challenges;
    _challengesCacheTime = DateTime.now();
    return challenges;
  }

  Future<Challenge?> fetchChallengeById(String id) async {
    final doc = await _challenges.doc(id).get();
    if (doc.exists) {
      return Challenge.fromDocument(doc);
    }
    return null;
  }

  Future<void> addChallenge(Challenge challenge) async {
    if (challenge.id.isNotEmpty) {
      await _challenges.doc(challenge.id).set(challenge.toMap());
    } else {
      await _challenges.add(challenge.toMap());
    }
  }

  Future<void> updateChallenge(Challenge challenge) async {
    await _challenges.doc(challenge.id).update(challenge.toMap());
  }
}
