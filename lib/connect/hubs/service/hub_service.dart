import '../model/hub_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    await hubsCollection.add({
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
    });
  }
}
