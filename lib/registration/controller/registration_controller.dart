import 'package:flutter/material.dart';
import '../models/registration_data.dart';
import '../service/registration_service.dart';
import '../../initial pages/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class RegistrationController extends ChangeNotifier {
  RegistrationData data = RegistrationData();
  int currentStep = 0;
  bool isLoading = false;
  final RegistrationService _service = RegistrationService();
  final AuthService _authService = AuthService();

  RegistrationController() {
    _initUniqueName();
  }

  void _initUniqueName() async {
    if (data.username == null || data.username!.isEmpty) {
      data.username = await _service.generateUniqueName();
      notifyListeners();
    }
  }

  void updateUniqueName(String name) {
    data.username = name;
    notifyListeners();
  }

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

  void updateEducationLevel(String? level) {
    data.educationLevel = level;
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

  // Load existing user data if available
  Future<void> loadExistingUserData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // This would require adding a method to RegistrationService to load user data
        // For now, we'll just check if user exists and set appropriate step
        // You can implement this later if needed
      }
    } catch (e) {
      debugPrint('Error loading existing user data: $e');
    }
  }

  Future<String?> submitRegistration(BuildContext context) async {
    setLoading(true);
    debugPrint('RegistrationController: Starting registration submission');
    try {
      // Request notification permissions before getting FCM token
      try {
        await FirebaseMessaging.instance.requestPermission();
      } catch (e) {
        debugPrint('Error requesting notification permission: $e');
      }

      // Get FCM token
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('FCM Token: ' + (fcmToken ?? 'null'));
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      final profileUrl = await _service.uploadProfileImage(data.profilePicPath);
      debugPrint('RegistrationController: Profile image uploaded: $profileUrl');

      final idCardUrl = await _service.uploadIdCard(data.idCardPath);
      debugPrint('RegistrationController: ID card uploaded: $idCardUrl');

      // Set date of join to now
      data.dateOfJoin = DateTime.now();

      await _service.saveUserData(
        data,
        profileUrl: profileUrl,
        idCardUrl: idCardUrl,
        fcmToken: fcmToken, // Pass the FCM token here
      );

      debugPrint('RegistrationController: Registration completed successfully');
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
