import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
part 'challenge_model.g.dart';

@HiveType(typeId: 0)
class Challenge {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final String imageUrl;
  @HiveField(4)
  final Timestamp deadline;
  @HiveField(5)
  final String prize;
  @HiveField(6)
  final String createdBy;
  @HiveField(7)
  final String skills;
  @HiveField(8)
  final String postType;
  @HiveField(9)
  final String whoCanWin;
  @HiveField(10)
  final String startDate;
  @HiveField(11)
  final String endDate;
  @HiveField(12)
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
