class RegistrationData {
  String? profilePicPath;
  String? fullName;
  DateTime? dob;
  String? gender;
  String? location;
  String? college;
  String? educationLevel; // 'Under Graduation' or 'Post Graduation'
  String? year;
  String? idCardPath;
  String? course;
  List<String> interests = [];
  DateTime? dateOfJoin;
  String? username; // Added for unique username

  RegistrationData();
}
