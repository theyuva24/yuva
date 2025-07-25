import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/registration_controller.dart';
import '../widgets/profile_image_picker.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/location_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../universal/theme/app_theme.dart';

class Step1PersonalInfo extends StatelessWidget {
  const Step1PersonalInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<RegistrationController>(context);
    String? genderValue = controller.data.gender;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
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
            //         color: AppThemeLight.accent, // was Color(0xFF00F6FF)
            //         letterSpacing: 4,
            //         shadows: [
            //           Shadow(
            //             blurRadius: 32,
            //             color: AppThemeLight.accent, // was Color(0xFF00F6FF)
            //             offset: Offset(0, 0),
            //           ),
            //           Shadow(
            //             blurRadius: 8,
            //             color: AppThemeLight.accent, // was Color(0xFF00F6FF)
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5.w,
                ),
              ),
            ),
            SizedBox(height: 32.h),
            Center(
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 3.w,
                  ),
                  // boxShadow removed to eliminate radiant glow
                ),
                child: ProfileImagePicker(
                  imagePath: controller.data.profilePicPath,
                  onImagePicked: controller.updateProfilePic,
                ),
              ),
            ),
            SizedBox(height: 32.h),
            // Full Name field
            TextFormField(
              initialValue: controller.data.fullName,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                hintText: 'Full Name',
                labelText: 'Full Name',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(
                    0.7,
                  ), // Dimmer color before input
                  fontWeight: FontWeight.w500,
                ),
                labelStyle: TextStyle(
                  color:
                      Theme.of(
                        context,
                      ).colorScheme.onSurface, // Ensure label is also dark
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20.h,
                  horizontal: 20.w,
                ),
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onChanged: controller.updateName,
            ),
            SizedBox(height: 20.h),
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
                prefixIcon: Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                hintText: 'Date of Birth',
                hintStyle: TextStyle(
                  color:
                      Theme.of(
                        context,
                      ).colorScheme.onSurface, // Ensure label is also dark
                  fontWeight: FontWeight.w500,
                ),
                labelStyle: TextStyle(
                  color:
                      Theme.of(
                        context,
                      ).colorScheme.onSurface, // Ensure label is also dark
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20.h,
                  horizontal: 20.w,
                ),
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 20.h),
            // Gender dropdown (already styled above)
            DropdownButtonFormField<String>(
              value: genderValue,
              items: [
                DropdownMenuItem(
                  value: 'M',
                  child: Row(
                    children: [
                      Icon(
                        Icons.male,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Male',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'F',
                  child: Row(
                    children: [
                      Icon(
                        Icons.female,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Female',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Other',
                  child: Row(
                    children: [
                      Icon(
                        Icons.transgender,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Other',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) controller.updateGender(val);
              },
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.people,
                  color: Theme.of(context).colorScheme.primary,
                ),
                hintText: 'Gender',
                hintStyle: TextStyle(
                  color:
                      Theme.of(
                        context,
                      ).colorScheme.onSurface, // Ensure label is also dark
                  fontWeight: FontWeight.w500,
                ),
                labelStyle: TextStyle(
                  color:
                      Theme.of(
                        context,
                      ).colorScheme.onSurface, // Ensure label is also dark
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20.h,
                  horizontal: 20.w,
                ),
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              dropdownColor: Theme.of(context).colorScheme.surface,
            ),
            SizedBox(height: 20.h),
            // Location field with neon style
            LocationPicker(
              initialLocation: controller.data.location,
              onLocationPicked: controller.updateLocation,
            ),
            SizedBox(height: 32.h),
            GradientButton(
              text: 'Next',
              onTap: () {
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
            ),
          ],
        ),
      ),
    );
  }
}
