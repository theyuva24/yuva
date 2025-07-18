import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import 'interests_card.dart';

class InterestsSection extends StatelessWidget {
  final ProfileModel profile;
  const InterestsSection({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InterestsCard(interests: profile.interests);
  }
}
