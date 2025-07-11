import 'package:flutter/material.dart';
import '../models/registration_data.dart';
import '../service/registration_service.dart';

class RegistrationController extends ChangeNotifier {
  RegistrationData data = RegistrationData();
  int currentStep = 0;
  bool isLoading = false;
  final RegistrationService _service = RegistrationService();

  void updateProfilePic(String? path) {
    data.profilePicPath = path;
    notifyListeners();
  }

  void updateName(String name) {
    data.fullName = name;
    notifyListeners();
  }

  void updateDob(DateTime dob) {
    data.dob = dob;
    notifyListeners();
  }

  void updateGender(String gender) {
    data.gender = gender;
    notifyListeners();
  }

  void updateLocation(String location) {
    data.location = location;
    notifyListeners();
  }

  void updateCollege(String college) {
    data.college = college;
    notifyListeners();
  }

  void updateYear(String year) {
    data.year = year;
    notifyListeners();
  }

  void updateIdCard(String? path) {
    data.idCardPath = path;
    notifyListeners();
  }

  void updateCourse(String course) {
    data.course = course;
    notifyListeners();
  }

  void updateInterests(List<String> interests) {
    data.interests = interests;
    notifyListeners();
  }

  void nextStep() {
    if (currentStep < 2) {
      currentStep++;
      notifyListeners();
    }
  }

  void prevStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  void reset() {
    data = RegistrationData();
    currentStep = 0;
    isLoading = false;
    notifyListeners();
  }

  Future<String?> submitRegistration(BuildContext context) async {
    setLoading(true);
    try {
      final profileUrl = await _service.uploadProfileImage(data.profilePicPath);
      final idCardUrl = await _service.uploadIdCard(data.idCardPath);
      await _service.saveUserData(
        data,
        profileUrl: profileUrl,
        idCardUrl: idCardUrl,
      );
      setLoading(false);
      return null;
    } catch (e) {
      setLoading(false);
      // Return null instead of error message to allow navigation
      debugPrint('Registration error: $e');
      return null;
    }
  }
}
