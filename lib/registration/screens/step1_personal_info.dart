import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/registration_controller.dart';
import '../widgets/profile_image_picker.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/location_picker.dart';

class Step1PersonalInfo extends StatelessWidget {
  const Step1PersonalInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<RegistrationController>(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: ProfileImagePicker(
                imagePath: controller.data.profilePicPath,
                onImagePicked: controller.updateProfilePic,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              initialValue: controller.data.fullName,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              onChanged: controller.updateName,
            ),
            const SizedBox(height: 20),
            DatePickerField(
              initialDate: controller.data.dob,
              onDatePicked: controller.updateDob,
            ),
            const SizedBox(height: 20),
            const Text('Gender', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    value: 'M',
                    groupValue: controller.data.gender,
                    onChanged: (val) {
                      if (val != null) controller.updateGender(val);
                    },
                    title: const Text('Male'),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    value: 'F',
                    groupValue: controller.data.gender,
                    onChanged: (val) {
                      if (val != null) controller.updateGender(val);
                    },
                    title: const Text('Female'),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    value: 'Other',
                    groupValue: controller.data.gender,
                    onChanged: (val) {
                      if (val != null) controller.updateGender(val);
                    },
                    title: const Text('Other'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LocationPicker(
              initialLocation: controller.data.location,
              onLocationPicked: controller.updateLocation,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
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
                // Validate fields (basic)
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
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
