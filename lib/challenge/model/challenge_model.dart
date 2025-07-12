import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final Timestamp deadline;
  final String prize;
  final String createdBy;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.deadline,
    required this.prize,
    required this.createdBy,
  });

  factory Challenge.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Challenge(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      deadline: data['deadline'] ?? Timestamp.now(),
      prize: data['prize'] ?? '',
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'deadline': deadline,
      'prize': prize,
      'createdBy': createdBy,
    };
  }
}
