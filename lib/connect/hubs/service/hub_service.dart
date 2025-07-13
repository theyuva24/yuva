import '../model/hub_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class HubService {
  final CollectionReference hubsCollection = FirebaseFirestore.instance
      .collection('Hubs');
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
}
