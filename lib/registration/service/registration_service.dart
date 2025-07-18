import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/registration_data.dart';

class RegistrationService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;

  // Generates a random student/GenZ-style unique name
  Future<String> generateUniqueName() async {
    final adjectives = [
      'Chill',
      'Vibe',
      'Epic',
      'Swift',
      'Nova',
      'Pixel',
      'Flex',
      'Hype',
      'Snazzy',
      'Lit',
      'Rad',
      'Fresh',
      'Savvy',
      'Quirky',
      'Zesty',
      'Witty',
      'Buzzy',
      'Snappy',
      'Groovy',
      'Peppy',
    ];
    final nouns = [
      'Scholar',
      'Nerd',
      'Guru',
      'Whiz',
      'Ace',
      'Wiz',
      'Pro',
      'Brain',
      'Geek',
      'Champ',
      'Scout',
      'Maven',
      'Scribe',
      'Coder',
      'Dreamer',
      'Creator',
      'Spark',
      'Legend',
      'Star',
      'Buddy',
    ];
    final random = DateTime.now().millisecondsSinceEpoch;
    String uniqueName;
    bool exists = true;
    int attempt = 0;
    do {
      final adj = adjectives[(random + attempt) % adjectives.length];
      final noun = nouns[(random * 7 + attempt * 13) % nouns.length];
      final number = (random + attempt * 17) % 10000;
      uniqueName = ' $adj$noun _ ${number.toString().padLeft(4, '0')}';
      final query =
          await _firestore
              .collection('users')
              .where('uniqueName', isEqualTo: uniqueName)
              .get();
      exists = query.docs.isNotEmpty;
      attempt++;
    } while (exists && attempt < 20);
    if (exists) {
      // fallback if too many attempts
      uniqueName = 'Student${random}';
    }
    return uniqueName;
  }

  Future<String?> uploadProfileImage(String? path) async {
    if (path == null) return null;
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');
      final ref = _storage.ref().child('users/$uid/profile.jpg');
      await ref.putFile(File(path));
      return await ref.getDownloadURL();
    } catch (e) {
      // Return null if upload fails, but don't throw
      debugPrint('Failed to upload profile image: $e');
      return null;
    }
  }

  Future<String?> uploadIdCard(String? path) async {
    if (path == null) return null;
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');
      final ref = _storage.ref().child('users/$uid/id_card.jpg');
      await ref.putFile(File(path));
      return await ref.getDownloadURL();
    } catch (e) {
      // Return null if upload fails, but don't throw
      debugPrint('Failed to upload ID card: $e');
      return null;
    }
  }

  Future<void> saveUserData(
    RegistrationData data, {
    String? profileUrl,
    String? idCardUrl,
    String? fcmToken,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      final phone = _auth.currentUser?.phoneNumber;
      if (uid == null) throw Exception('User not logged in');

      debugPrint('RegistrationService: Saving data for user $uid');
      debugPrint(
        'RegistrationService: Data to save: ${data.fullName}, ${data.college}, ${data.interests}',
      );

      // Generate and assign a unique name if not already set
      if (data.username == null || data.username!.isEmpty) {
        data.username = await generateUniqueName();
      }

      // Check if user data already exists
      final existingDoc = await _firestore.collection('users').doc(uid).get();

      if (existingDoc.exists) {
        debugPrint('RegistrationService: Updating existing user data');
        // Update existing user data
        await _firestore.collection('users').doc(uid).update({
          'profilePicUrl': profileUrl ?? existingDoc.data()?['profilePicUrl'],
          'fullName': data.fullName,
          'dob': data.dob?.toIso8601String(),
          'gender': data.gender,
          'location': data.location,
          'college': data.college,
          'year': data.year,
          'idCardUrl': idCardUrl ?? existingDoc.data()?['idCardUrl'],
          'course': data.course,
          'interests': data.interests,
          'phone': phone,
          'fcmToken': fcmToken,
          'uniqueName': data.username, // Save as uniqueName
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        debugPrint('RegistrationService: Creating new user data');
        // Create new user data
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
          'fcmToken': fcmToken,
          'uniqueName': data.username, // Save as uniqueName
          'createdAt': FieldValue.serverTimestamp(),
          'joinedHubs': [], // Always initialize joinedHubs for new users
        });
      }

      debugPrint('RegistrationService: User data saved successfully');
    } catch (e) {
      // Log the error but don't throw
      debugPrint('Failed to save user data: $e');
      // You could also save to local storage as a fallback
    }
  }
}
