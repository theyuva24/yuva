import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/profile_model.dart';
import 'dart:io';

class ProfileService {
  final _firestore = FirebaseFirestore.instance;
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
}
