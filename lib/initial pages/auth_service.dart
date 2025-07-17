import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if user is authenticated and has completed registration
  Future<bool> isUserFullyRegistered() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('AuthService: No current user found');
        return false;
      }

      debugPrint('AuthService: Checking registration for user ${user.uid}');

      // Check if user data exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final exists = userDoc.exists;

      debugPrint('AuthService: User document exists: $exists');
      if (exists) {
        debugPrint('AuthService: User data: ${userDoc.data()}');
      }

      return exists;
    } catch (e) {
      debugPrint('Error checking user registration: $e');
      return false;
    }
  }

  // Check if a user exists by phone number
  Future<bool> doesUserExistByPhone(String phoneNumber) async {
    try {
      debugPrint(
        'AuthService: Checking if user exists with phone: $phoneNumber',
      );

      final querySnapshot =
          await _firestore
              .collection('users')
              .where('phone', isEqualTo: phoneNumber)
              .limit(1)
              .get();

      final exists = querySnapshot.docs.isNotEmpty;
      debugPrint('AuthService: User exists with phone $phoneNumber: $exists');

      if (exists) {
        debugPrint(
          'AuthService: Found user data: ${querySnapshot.docs.first.data()}',
        );
      }

      return exists;
    } catch (e) {
      debugPrint('AuthService: Error checking user existence by phone: $e');
      return false;
    }
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is only authenticated (but might not have completed registration)
  bool isUserAuthenticated() {
    return _auth.currentUser != null;
  }

  // Check if user is authenticated but not fully registered
  Future<bool> isUserAuthenticatedButNotRegistered() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if user data exists in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      return !userDoc
          .exists; // User is authenticated but has no data in Firestore
    } catch (e) {
      debugPrint('Error checking user registration status: $e');
      return false;
    }
  }

  // Sign out user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current authentication state for debugging
  void debugAuthState() {
    final user = _auth.currentUser;
    debugPrint('AuthService: Current user: ${user?.uid}');
    debugPrint('AuthService: User email: ${user?.email}');
    debugPrint('AuthService: User phone: ${user?.phoneNumber}');
    debugPrint('AuthService: User display name: ${user?.displayName}');
  }
}
