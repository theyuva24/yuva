import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/registration_controller.dart';
import '../widgets/id_card_picker.dart';
import '../../universal/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/college_autocomplete_field.dart';
import '../widgets/course_autocomplete_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Step2EducationInfo extends StatelessWidget {
  const Step2EducationInfo({super.key});

  static const List<String> years = [
    '1st year',
    '2nd year',
    '3rd year',
    '4th year',
    '5th year',
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<RegistrationController>(context);
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
                'Academic Information',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5.w,
                ),
              ),
            ),
            SizedBox(height: 32.h),
            // College Autocomplete
            CollegeAutocompleteField(
              initialValue: controller.data.college,
              onSelected: controller.updateCollege,
            ),
            SizedBox(height: 20.h),
            // Course Autocomplete (optional, similar logic)
            CourseAutocompleteField(
              initialValue: controller.data.course,
              onSelected: controller.updateCourse,
            ),
            SizedBox(height: 20.h),
            DropdownButtonFormField<String>(
              value: controller.data.year,
              items:
                  years
                      .map(
                        (y) => DropdownMenuItem(
                          value: y,
                          child: Text(
                            y,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppThemeLight.textDark),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (val) {
                if (val != null) controller.updateYear(val);
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.calendar_month,
                  color: AppThemeLight.primary,
                ),
                hintText: 'Current Year',
                hintStyle: TextStyle(color: AppThemeLight.textLight),
                filled: true,
                fillColor: AppThemeLight.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20.h,
                  horizontal: 20.w,
                ),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppThemeLight.textDark),
              dropdownColor: AppThemeLight.surface,
            ),
            SizedBox(height: 20.h),
            // College ID Image
            Text(
              'College ID Image',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppThemeLight.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            IdCardPicker(
              imagePath: controller.data.idCardPath,
              onImagePicked: controller.updateIdCard,
            ),
            SizedBox(height: 32.h),
            GradientButton(
              text: 'Next',
              onTap: () {
                if (controller.data.college == null ||
                    controller.data.college!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select your college')),
                  );
                  return;
                }
                if (controller.data.year == null ||
                    controller.data.year!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select your current year'),
                    ),
                  );
                  return;
                }
                if (controller.data.idCardPath == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please upload your college ID'),
                    ),
                  );
                  return;
                }
                if (controller.data.course == null ||
                    controller.data.course!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your course')),
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
