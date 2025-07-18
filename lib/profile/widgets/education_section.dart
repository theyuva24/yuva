import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import 'education_info_card.dart';

class EducationSection extends StatelessWidget {
  final ProfileModel profile;
  const EducationSection({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EducationInfoCard(
      college: profile.college,
      course: profile.course,
      year: profile.year,
    );
  }
}
