import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/profile_model.dart';
import 'dart:io';

Map<String, ProfileModel> _profileCache = {};
Map<String, DateTime> _profileCacheTime = {};
const Duration _profileCacheDuration = Duration(minutes: 5);

void clearProfileCache([String? uid]) {
  if (uid != null) {
    _profileCache.remove(uid);
    _profileCacheTime.remove(uid);
  } else {
    _profileCache.clear();
    _profileCacheTime.clear();
  }
}

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<ProfileModel?> getProfile(
    String uid, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _profileCache.containsKey(uid) &&
        _profileCacheTime[uid] != null &&
        DateTime.now().difference(_profileCacheTime[uid]!) <
            _profileCacheDuration) {
      return _profileCache[uid];
    }
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      final profile = ProfileModel.fromMap(doc.data()!, uid);
      _profileCache[uid] = profile;
      _profileCacheTime[uid] = DateTime.now();
      return profile;
    }
    return null;
  }

  Future<void> updateProfile(ProfileModel profile) async {
    await _firestore
        .collection('users')
        .doc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  Future<String> uploadProfileImage(String uid, String filePath) async {
    if (filePath.isEmpty) return '';
    final ref = _storage.ref().child('profile_images/$uid.jpg');
    final uploadTask = await ref.putFile(File(filePath));
    return await uploadTask.ref.getDownloadURL();
  }
}
