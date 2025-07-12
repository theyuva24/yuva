import '../model/hub_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class HubService {
  final CollectionReference hubsCollection = FirebaseFirestore.instance
      .collection('Hubs');

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
    final docRef = await hubsCollection.add({
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
    });
    // Save the hub id as a field in the document
    await docRef.update({'id': docRef.id});
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
      'id': id,
    });
  }

  Future<String?> uploadHubImage(String? path, String hubId) async {
    if (path == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref().child('hubs/$hubId/image.jpg');
      await ref.putFile(File(path));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Failed to upload hub image: $e');
      return null;
    }
  }
}
