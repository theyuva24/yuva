import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/registration_controller.dart';
import '../widgets/profile_image_picker.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/location_picker.dart';
import '../../universal/theme/gradient_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class Step1PersonalInfo extends StatelessWidget {
  const Step1PersonalInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<RegistrationController>(context);
    String? genderValue = controller.data.gender;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Neon YUVA logo (REMOVED)
            // Center(
            //   child: Text(
            //     'YUVA',
            //     style: GoogleFonts.orbitron(
            //       textStyle: const TextStyle(
            //         fontSize: 56,
            //         fontWeight: FontWeight.bold,
            //         color: Color(0xFF00F6FF),
            //         letterSpacing: 4,
            //         shadows: [
            //           Shadow(
            //             blurRadius: 32,
            //             color: Color(0xFF00F6FF),
            //             offset: Offset(0, 0),
            //           ),
            //           Shadow(
            //             blurRadius: 8,
            //             color: Color(0xFF00F6FF),
            //             offset: Offset(0, 0),
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 8),
            Center(
              child: Text(
                'Create your account',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFF00F6FF), width: 3),
                  // boxShadow removed to eliminate radiant glow
                ),
                child: ProfileImagePicker(
                  imagePath: controller.data.profilePicPath,
                  onImagePicked: controller.updateProfilePic,
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              initialValue: controller.data.fullName,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person, color: Color(0xFF00F6FF)),
                hintText: 'Username',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: const Color(0xFF181C23),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 18),
              onChanged: controller.updateName,
            ),
            const SizedBox(height: 20),
            // Date of Birth field with neon style
            TextFormField(
              readOnly: true,
              onTap: () async {
                FocusScope.of(context).requestFocus(FocusNode());
                final now = DateTime.now();
                final minDate = DateTime(now.year - 100, now.month, now.day);
                final maxDate = DateTime(now.year - 13, now.month, now.day);
                final picked = await showDatePicker(
                  context: context,
                  initialDate: controller.data.dob ?? maxDate,
                  firstDate: minDate,
                  lastDate: maxDate,
                );
                FocusScope.of(context).requestFocus(FocusNode());
                if (picked != null) controller.updateDob(picked);
              },
              controller: TextEditingController(
                text:
                    controller.data.dob != null
                        ? DateFormat('dd MMM yyyy').format(controller.data.dob!)
                        : '',
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF00F6FF),
                ),
                hintText: 'Date of Birth',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: const Color(0xFF181C23),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            // Gender dropdown (already styled above)
            DropdownButtonFormField<String>(
              value: genderValue,
              items: const [
                DropdownMenuItem(
                  value: 'M',
                  child: Row(
                    children: [
                      Icon(Icons.male, color: Color(0xFF00F6FF)),
                      SizedBox(width: 8),
                      Text('Male'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'F',
                  child: Row(
                    children: [
                      Icon(Icons.female, color: Color(0xFF00F6FF)),
                      SizedBox(width: 8),
                      Text('Female'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Other',
                  child: Row(
                    children: [
                      Icon(Icons.transgender, color: Color(0xFF00F6FF)),
                      SizedBox(width: 8),
                      Text('Other'),
                    ],
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) controller.updateGender(val);
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.people, color: Color(0xFF00F6FF)),
                hintText: 'Gender',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: const Color(0xFF181C23),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 18),
              dropdownColor: const Color(0xFF181C23),
            ),
            const SizedBox(height: 20),
            // Location field with neon style
            LocationPicker(
              initialLocation: controller.data.location,
              onLocationPicked: controller.updateLocation,
            ),
            const SizedBox(height: 32),
            GradientButton(
              onPressed: () {
                if (controller.data.profilePicPath == null ||
                    controller.data.profilePicPath!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a profile image'),
                    ),
                  );
                  return;
                }
                if (controller.data.fullName == null ||
                    controller.data.fullName!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your name')),
                  );
                  return;
                }
                if (controller.data.dob == null ||
                    DateTime.now().difference(controller.data.dob!).inDays <
                        365 * 13) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You must be at least 13 years old'),
                    ),
                  );
                  return;
                }
                if (controller.data.gender == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select your gender')),
                  );
                  return;
                }
                if (controller.data.location == null ||
                    controller.data.location!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select your location'),
                    ),
                  );
                  return;
                }
                controller.nextStep();
              },
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const Text(
                'Next',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
