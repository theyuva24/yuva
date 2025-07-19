import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/challenge_model.dart';
import 'package:hive/hive.dart';

List<Challenge>? _cachedChallenges;
DateTime? _challengesCacheTime;
const Duration _challengesCacheDuration = Duration(hours: 1);

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
    final box = Hive.box('challenges');
    final cacheTime = box.get('cacheTime') as DateTime?;
    final cachedList = box.get('list') as List?;
    if (!forceRefresh &&
        cachedList != null &&
        cacheTime != null &&
        DateTime.now().difference(cacheTime) < _challengesCacheDuration) {
      return List<Challenge>.from(cachedList.cast<Challenge>());
    }
    final snapshot =
        await _challenges.orderBy('deadline', descending: false).get();
    final challenges =
        snapshot.docs.map((doc) => Challenge.fromDocument(doc)).toList();
    await box.put('list', challenges);
    await box.put('cacheTime', DateTime.now());
    return challenges;
  }

  Future<Challenge?> fetchChallengeById(
    String id, {
    bool forceRefresh = false,
  }) async {
    final box = Hive.box('challenge_details');
    final cacheKey = 'detail_$id';
    final cacheTimeKey = 'detail_time_$id';
    final cacheTime = box.get(cacheTimeKey) as DateTime?;
    final cachedDetail = box.get(cacheKey) as Challenge?;
    if (!forceRefresh &&
        cachedDetail != null &&
        cacheTime != null &&
        DateTime.now().difference(cacheTime) < _challengesCacheDuration) {
      return cachedDetail;
    }
    final doc = await _challenges.doc(id).get();
    if (doc.exists) {
      final challenge = Challenge.fromDocument(doc);
      await box.put(cacheKey, challenge);
      await box.put(cacheTimeKey, DateTime.now());
      return challenge;
    }
    return null;
  }

  Future<void> addChallenge(Challenge challenge) async {
    if (challenge.id.isNotEmpty) {
      await _challenges.doc(challenge.id).set(challenge.toMap());
    } else {
      await _challenges.add(challenge.toMap());
    }
    // Invalidate cache
    final box = Hive.box('challenges');
    await box.delete('list');
    await box.delete('cacheTime');
  }

  Future<void> updateChallenge(Challenge challenge) async {
    await _challenges.doc(challenge.id).update(challenge.toMap());
    // Invalidate cache
    final box = Hive.box('challenges');
    await box.delete('list');
    await box.delete('cacheTime');
    final detailBox = Hive.box('challenge_details');
    await detailBox.delete('detail_${challenge.id}');
    await detailBox.delete('detail_time_${challenge.id}');
  }
}
