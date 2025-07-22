import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/challenge_model.dart';
import 'package:hive/hive.dart';
import 'dart:async';

List<Challenge>? _cachedChallenges;
DateTime? _challengesCacheTime;
final Map<String, Challenge> _inMemoryChallengeDetails = {};
final List<String> _challengeDetailLRU = [];
const int _challengeDetailCacheLimit = 30;
DateTime? _challengeDetailsCacheTime;
List<Challenge>? _inMemoryChallengeList;
DateTime? _inMemoryChallengeListTime;
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
    // In-memory cache first
    if (!forceRefresh &&
        _inMemoryChallengeList != null &&
        _inMemoryChallengeListTime != null &&
        DateTime.now().difference(_inMemoryChallengeListTime!) <
            _challengesCacheDuration) {
      return _inMemoryChallengeList!;
    }
    final box = Hive.box('challenges');
    List<Challenge>? cachedList;
    DateTime? cacheTime;
    try {
      cacheTime = box.get('cacheTime') as DateTime?;
      final rawList = box.get('list') as List<dynamic>?;
      cachedList = rawList?.cast<Challenge>();
    } catch (_) {
      cachedList = null;
      cacheTime = null;
    }
    if (!forceRefresh &&
        cachedList != null &&
        cacheTime != null &&
        DateTime.now().difference(cacheTime) < _challengesCacheDuration) {
      // Start background refresh
      _backgroundRefreshChallenges();
      _inMemoryChallengeList = List<Challenge>.from(
        cachedList.cast<Challenge>(),
      );
      _inMemoryChallengeListTime = cacheTime;
      return _inMemoryChallengeList!;
    }
    // Fetch from network
    final snapshot =
        await _challenges.orderBy('deadline', descending: false).get();
    final challenges =
        snapshot.docs.map((doc) => Challenge.fromDocument(doc)).toList();
    await box.put('list', challenges);
    await box.put('cacheTime', DateTime.now());
    _inMemoryChallengeList = challenges;
    _inMemoryChallengeListTime = DateTime.now();
    return challenges;
  }

  void _backgroundRefreshChallenges() async {
    try {
      final snapshot =
          await _challenges.orderBy('deadline', descending: false).get();
      final challenges =
          snapshot.docs.map((doc) => Challenge.fromDocument(doc)).toList();
      final box = Hive.box('challenges');
      await box.put('list', challenges);
      await box.put('cacheTime', DateTime.now());
      _inMemoryChallengeList = challenges;
      _inMemoryChallengeListTime = DateTime.now();
    } catch (_) {}
  }

  Future<Challenge?> fetchChallengeById(
    String id, {
    bool forceRefresh = false,
  }) async {
    // In-memory cache first
    if (!forceRefresh && _inMemoryChallengeDetails.containsKey(id)) {
      return _inMemoryChallengeDetails[id];
    }
    final box = Hive.box('challenge_details');
    final cacheKey = 'detail_$id';
    final cacheTimeKey = 'detail_time_$id';
    Challenge? cachedDetail;
    DateTime? cacheTime;
    try {
      cacheTime = box.get(cacheTimeKey) as DateTime?;
      cachedDetail = box.get(cacheKey) as Challenge?;
    } catch (_) {
      cachedDetail = null;
      cacheTime = null;
    }
    if (!forceRefresh &&
        cachedDetail != null &&
        cacheTime != null &&
        DateTime.now().difference(cacheTime) < _challengesCacheDuration) {
      // Start background refresh
      _backgroundRefreshChallengeDetail(id);
      _updateInMemoryDetailCache(id, cachedDetail);
      return cachedDetail;
    }
    // Fetch from network
    final doc = await _challenges.doc(id).get();
    if (doc.exists) {
      final challenge = Challenge.fromDocument(doc);
      await box.put(cacheKey, challenge);
      await box.put(cacheTimeKey, DateTime.now());
      _updateInMemoryDetailCache(id, challenge);
      return challenge;
    }
    return null;
  }

  void _backgroundRefreshChallengeDetail(String id) async {
    try {
      final doc = await _challenges.doc(id).get();
      if (doc.exists) {
        final challenge = Challenge.fromDocument(doc);
        final box = Hive.box('challenge_details');
        await box.put('detail_$id', challenge);
        await box.put('detail_time_$id', DateTime.now());
        _updateInMemoryDetailCache(id, challenge);
      }
    } catch (_) {}
  }

  void _updateInMemoryDetailCache(String id, Challenge challenge) {
    _inMemoryChallengeDetails[id] = challenge;
    // LRU management
    _challengeDetailLRU.remove(id);
    _challengeDetailLRU.insert(0, id);
    if (_challengeDetailLRU.length > _challengeDetailCacheLimit) {
      final removeId = _challengeDetailLRU.removeLast();
      _inMemoryChallengeDetails.remove(removeId);
    }
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
    _inMemoryChallengeList = null;
    _inMemoryChallengeListTime = null;
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
    _inMemoryChallengeDetails.remove(challenge.id);
    _challengeDetailLRU.remove(challenge.id);
  }
}
