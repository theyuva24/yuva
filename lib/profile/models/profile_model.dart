import 'package:cloud_firestore/cloud_firestore.dart';
import 'experience_model.dart';
import 'education_model.dart';

class ContactInfo {
  final String email;
  final String linkedInUrl;
  final String phone;
  ContactInfo({this.email = '', this.linkedInUrl = '', this.phone = ''});
  factory ContactInfo.fromMap(Map<String, dynamic> map) => ContactInfo(
    email: map['email'] ?? '',
    linkedInUrl: map['linkedInUrl'] ?? '',
    phone: map['phone'] ?? '',
  );
  Map<String, dynamic> toMap() => {
    'email': email,
    'linkedInUrl': linkedInUrl,
    'phone': phone,
  };

  ContactInfo copyWith({String? email, String? linkedInUrl, String? phone}) {
    return ContactInfo(
      email: email ?? this.email,
      linkedInUrl: linkedInUrl ?? this.linkedInUrl,
      phone: phone ?? this.phone,
    );
  }
}

class ProfileModel {
  final String uid;
  final String fullName;
  final String phone;
  final String gender;
  final DateTime? dob;
  final String college;
  final String educationLevel;
  final String course;
  final String year;
  final String location;
  final List<String> interests;
  final String profilePicUrl;
  final String idCardUrl;
  final String uniqueName;
  final String bio;
  final String headline;
  final String backgroundBannerUrl;
  final int connectionsCount;
  final ContactInfo contactInfo;
  final List<ExperienceModel> experience;
  final List<EducationModel> education;
  final List<String> skills;

  ProfileModel({
    required this.uid,
    required this.fullName,
    required this.phone,
    required this.gender,
    this.dob,
    required this.college,
    required this.educationLevel,
    required this.course,
    required this.year,
    required this.location,
    required this.interests,
    required this.profilePicUrl,
    required this.idCardUrl,
    required this.uniqueName,
    required this.bio,
    this.headline = '',
    this.backgroundBannerUrl = '',
    this.connectionsCount = 0,
    ContactInfo? contactInfo,
    List<ExperienceModel>? experience,
    List<EducationModel>? education,
    List<String>? skills,
  }) : contactInfo = contactInfo ?? ContactInfo(),
       experience = experience ?? const [],
       education = education ?? const [],
       skills = skills ?? const [];

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
      educationLevel: map['educationLevel'] ?? '',
      course: map['course'] ?? '',
      year: map['year'] ?? '',
      location: map['location'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      profilePicUrl: map['profilePicUrl'] ?? '',
      idCardUrl: map['idCardUrl'] ?? '',
      uniqueName: map['uniqueName'] ?? '',
      bio: map['bio'] ?? '',
      headline: map['headline'] ?? '',
      backgroundBannerUrl: map['backgroundBannerUrl'] ?? '',
      connectionsCount: map['connectionsCount'] ?? 0,
      contactInfo:
          map['contactInfo'] != null
              ? ContactInfo.fromMap(
                Map<String, dynamic>.from(map['contactInfo']),
              )
              : ContactInfo(),
      experience:
          map['experience'] != null
              ? List<Map<String, dynamic>>.from(
                map['experience'],
              ).map((e) => ExperienceModel.fromMap(e)).toList()
              : [],
      education:
          map['education'] != null
              ? List<Map<String, dynamic>>.from(
                map['education'],
              ).map((e) => EducationModel.fromMap(e)).toList()
              : [],
      skills: List<String>.from(map['skills'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'gender': gender,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,
      'college': college,
      'educationLevel': educationLevel,
      'course': course,
      'year': year,
      'location': location,
      'interests': interests,
      'profilePicUrl': profilePicUrl,
      'idCardUrl': idCardUrl,
      'uniqueName': uniqueName,
      'bio': bio,
      'headline': headline,
      'backgroundBannerUrl': backgroundBannerUrl,
      'connectionsCount': connectionsCount,
      'contactInfo': contactInfo.toMap(),
      'experience': experience.map((e) => e.toMap()).toList(),
      'education': education.map((e) => e.toMap()).toList(),
      'skills': skills,
    };
  }

  ProfileModel copyWith({
    String? fullName,
    String? phone,
    String? gender,
    DateTime? dob,
    String? college,
    String? educationLevel,
    String? course,
    String? year,
    String? location,
    List<String>? interests,
    String? profilePicUrl,
    String? idCardUrl,
    String? uniqueName,
    String? bio,
    String? headline,
    String? backgroundBannerUrl,
    int? connectionsCount,
    ContactInfo? contactInfo,
    List<ExperienceModel>? experience,
    List<EducationModel>? education,
    List<String>? skills,
  }) {
    return ProfileModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      college: college ?? this.college,
      educationLevel: educationLevel ?? this.educationLevel,
      course: course ?? this.course,
      year: year ?? this.year,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      idCardUrl: idCardUrl ?? this.idCardUrl,
      uniqueName: uniqueName ?? this.uniqueName,
      bio: bio ?? this.bio,
      headline: headline ?? this.headline,
      backgroundBannerUrl: backgroundBannerUrl ?? this.backgroundBannerUrl,
      connectionsCount: connectionsCount ?? this.connectionsCount,
      contactInfo: contactInfo ?? this.contactInfo,
      experience: experience ?? this.experience,
      education: education ?? this.education,
      skills: skills ?? this.skills,
    );
  }
}
