import '../models/hub_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HubService {
  final CollectionReference hubsCollection = FirebaseFirestore.instance
      .collection('hubs');
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Hub>> getHubsStream() {
    return hubsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Hub(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
        );
      }).toList();
    });
  }

  Future<void> createHub({
    required String name,
    required String description,
    required String imageUrl,
  }) async {
    await hubsCollection.add({
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
    });
  }

  Future<String?> uploadHubImage(String? path, String hubId) async {
    if (path == null) return null;
    try {
      final ref = _storage.ref().child('hubs/$hubId/hub_image.jpg');
      await ref.putFile(File(path));
      return await ref.getDownloadURL();
    } catch (e) {
      // Return null if upload fails, but don't throw
      debugPrint('Failed to upload hub image: $e');
      return null;
    }
  }

  Future<void> updateHub({
    required String id,
    required String name,
    required String description,
    required String imageUrl,
  }) async {
    await hubsCollection.doc(id).update({
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
    });
  }

  /// Join a hub: adds hubId to user's joinedHubs array in Firestore
  Future<void> joinHub(String hubId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final userRef = _firestore.collection('users').doc(user.uid);
    try {
      await userRef.update({
        'joinedHubs': FieldValue.arrayUnion([hubId]),
      });
      print('[HubService] User ${user.uid} joined hub $hubId');
    } catch (e) {
      print('[HubService] Failed to join hub: $e');
      rethrow;
    }
  }

  /// Leave a hub: removes hubId from user's joinedHubs array in Firestore
  Future<void> leaveHub(String hubId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final userRef = _firestore.collection('users').doc(user.uid);
    try {
      await userRef.update({
        'joinedHubs': FieldValue.arrayRemove([hubId]),
      });
      print('[HubService] User ${user.uid} left hub $hubId');
    } catch (e) {
      print('[HubService] Failed to leave hub: $e');
      rethrow;
    }
  }

  /// Get a stream of the user's joined hubs (for real-time updates)
  Stream<List<String>> getJoinedHubsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return <String>[];
      final joined = data['joinedHubs'] as List<dynamic>? ?? [];
      return joined.map((e) => e.toString()).toList();
    });
  }
}
