import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileModel {
  final String uid;
  final String fullName;
  final String phone;
  final String gender;
  final DateTime? dob;
  final String college;
  final String course;
  final String year;
  final String location;
  final List<String> interests;
  final String profilePicUrl;
  final String idCardUrl;
  final List<String> followers;
  final List<String> following;

  ProfileModel({
    required this.uid,
    required this.fullName,
    required this.phone,
    required this.gender,
    this.dob,
    required this.college,
    required this.course,
    required this.year,
    required this.location,
    required this.interests,
    required this.profilePicUrl,
    required this.idCardUrl,
    required this.followers,
    required this.following,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map, String uid) {
    return ProfileModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      gender: map['gender'] ?? '',
      dob:
          map['dob'] != null
              ? (map['dob'] is Timestamp
                  ? (map['dob'] as Timestamp).toDate()
                  : DateTime.tryParse(map['dob'].toString()))
              : null,
      college: map['college'] ?? '',
      course: map['course'] ?? '',
      year: map['year'] ?? '',
      location: map['location'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      profilePicUrl: map['profilePicUrl'] ?? '',
      idCardUrl: map['idCardUrl'] ?? '',
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'gender': gender,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'college': college,
      'course': course,
      'year': year,
      'location': location,
      'interests': interests,
      'profilePicUrl': profilePicUrl,
      'idCardUrl': idCardUrl,
      'followers': followers,
      'following': following,
    };
  }
}
