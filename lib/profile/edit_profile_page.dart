import 'package:flutter/material.dart';
import 'models/profile_model.dart';

class EditProfilePage extends StatelessWidget {
  final ProfileModel profile;
  const EditProfilePage({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF0A0E17),
      ),
      backgroundColor: const Color(0xFF0A0E17),
      body: const Center(
        child: Text('Edit Profile Page', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
