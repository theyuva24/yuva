import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/profile_model.dart';
import 'dart:io';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<ProfileModel?> getProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return ProfileModel.fromMap(doc.data()!, uid);
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

  // Add follow and unfollow methods
  Future<void> followUser(String currentUserId, String targetUserId) async {
    final batch = _firestore.batch();

    // Add to target user's followers
    final followerRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);
    batch.set(followerRef, {'followedAt': FieldValue.serverTimestamp()});

    // Add to current user's following
    final followingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);
    batch.set(followingRef, {'followedAt': FieldValue.serverTimestamp()});

    await batch.commit();
  }

  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    final batch = _firestore.batch();

    // Remove from target user's followers
    final followerRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);
    batch.delete(followerRef);

    // Remove from current user's following
    final followingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);
    batch.delete(followingRef);

    await batch.commit();
  }

  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    final doc =
        await _firestore
            .collection('users')
            .doc(targetUserId)
            .collection('followers')
            .doc(currentUserId)
            .get();
    return doc.exists;
  }
}
