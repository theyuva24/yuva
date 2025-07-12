import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final Timestamp deadline;
  final String prize;
  final String createdBy;
  final String skills;
  final String postType;
  final String whoCanWin;
  final String startDate;
  final String endDate;
  final String link;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.deadline,
    required this.prize,
    required this.createdBy,
    required this.skills,
    required this.postType,
    required this.whoCanWin,
    required this.startDate,
    required this.endDate,
    required this.link,
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
      skills: data['skills'] ?? '',
      postType: data['postType'] ?? '',
      whoCanWin: data['whoCanWin'] ?? '',
      startDate: data['startDate'] ?? '',
      endDate: data['endDate'] ?? '',
      link: data['link'] ?? '',
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
      'skills': skills,
      'postType': postType,
      'whoCanWin': whoCanWin,
      'startDate': startDate,
      'endDate': endDate,
      'link': link,
    };
  }
}
