import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/registration_data.dart';

class RegistrationService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  Future<String?> uploadProfileImage(String? path) async {
    if (path == null) return null;
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');
    final ref = _storage.ref().child('users/$uid/profile.jpg');
    await ref.putFile(File(path));
    return await ref.getDownloadURL();
  }

  Future<String?> uploadIdCard(String? path) async {
    if (path == null) return null;
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');
    final ref = _storage.ref().child('users/$uid/id_card.jpg');
    await ref.putFile(File(path));
    return await ref.getDownloadURL();
  }

  Future<void> saveUserData(
    RegistrationData data, {
    String? profileUrl,
    String? idCardUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    final phone = _auth.currentUser?.phoneNumber;
    if (uid == null) throw Exception('User not logged in');
    await _firestore.collection('users').doc(uid).set({
      'profilePicUrl': profileUrl,
      'fullName': data.fullName,
      'dob': data.dob?.toIso8601String(),
      'gender': data.gender,
      'location': data.location,
      'college': data.college,
      'year': data.year,
      'idCardUrl': idCardUrl,
      'course': data.course,
      'interests': data.interests,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
