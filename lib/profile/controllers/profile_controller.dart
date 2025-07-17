import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile_model.dart';
import '../services/profile_service.dart';
import 'dart:io';

class ProfileController extends ChangeNotifier {
  final ProfileService _service = ProfileService();
  ProfileModel? profile;
  bool isLoading = false;
  bool isEditing = false;

  // Field controllers
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final genderController = TextEditingController();
  DateTime? dob;
  final collegeController = TextEditingController();
  final courseController = TextEditingController();
  final yearController = TextEditingController();
  final locationController = TextEditingController();
  List<String> interests = [];
  String profilePicUrl = '';
  String idCardUrl = '';

  Future<void> loadProfile(String uid) async {
    isLoading = true;
    notifyListeners();
    profile = await _service.getProfile(uid);
    if (profile != null) {
      fullNameController.text = profile!.fullName;
      phoneController.text = profile!.phone;
      genderController.text = profile!.gender;
      dob = profile!.dob;
      collegeController.text = profile!.college;
      courseController.text = profile!.course;
      yearController.text = profile!.year;
      locationController.text = profile!.location;
      interests = List<String>.from(profile!.interests);
      profilePicUrl = profile!.profilePicUrl;
      idCardUrl = profile!.idCardUrl;
    }
    isLoading = false;
    notifyListeners();
  }

  void setEditing(bool editing) {
    isEditing = editing;
    notifyListeners();
  }

  Future<void> pickProfileImage(String uid) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      isLoading = true;
      notifyListeners();
      final url = await _service.uploadProfileImage(uid, picked.path);
      profilePicUrl = url;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile(String uid) async {
    isLoading = true;
    notifyListeners();
    final updated = ProfileModel(
      uid: uid,
      fullName: fullNameController.text.trim(),
      phone: phoneController.text.trim(),
      gender: genderController.text.trim(),
      dob: dob,
      college: collegeController.text.trim(),
      course: courseController.text.trim(),
      year: yearController.text.trim(),
      location: locationController.text.trim(),
      interests: interests,
      profilePicUrl: profilePicUrl,
      idCardUrl: idCardUrl,
      followers: profile?.followers ?? [],
      following: profile?.following ?? [],
    );
    await _service.updateProfile(updated);
    profile = updated;
    isEditing = false;
    isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    genderController.dispose();
    collegeController.dispose();
    courseController.dispose();
    yearController.dispose();
    locationController.dispose();
    super.dispose();
  }
}
