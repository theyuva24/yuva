import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/registration_controller.dart';
import '../widgets/id_card_picker.dart';
import '../../core/theme/gradient_button.dart';
import 'package:google_fonts/google_fonts.dart';

class Step2EducationInfo extends StatelessWidget {
  const Step2EducationInfo({super.key});

  static const List<String> years = ['1st', '2nd', 'Graduate'];

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<RegistrationController>(context);
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
                'Academic Information',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              initialValue: controller.data.college,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.school, color: Color(0xFF00F6FF)),
                hintText: 'College/Institution',
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
              onChanged: controller.updateCollege,
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: controller.data.course,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.collections_bookmark,
                  color: Color(0xFF00F6FF),
                ),
                hintText: 'Course',
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
              onChanged: controller.updateCourse,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: controller.data.year,
              items:
                  years
                      .map(
                        (y) => DropdownMenuItem(
                          value: y,
                          child: Text(y, style: TextStyle(color: Colors.white)),
                        ),
                      )
                      .toList(),
              onChanged: (val) {
                if (val != null) controller.updateYear(val);
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.calendar_month,
                  color: Color(0xFF00F6FF),
                ),
                hintText: 'Current Year',
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
            // College ID Image
            const Text(
              'College ID Image',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            IdCardPicker(
              imagePath: controller.data.idCardPath,
              onImagePicked: controller.updateIdCard,
            ),
            const SizedBox(height: 32),
            GradientButton(
              onPressed: () {
                if (controller.data.college == null ||
                    controller.data.college!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your college')),
                  );
                  return;
                }
                if (controller.data.year == null ||
                    controller.data.year!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select your year')),
                  );
                  return;
                }
                if (controller.data.idCardPath == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please upload your college ID card'),
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
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const Text(
                'Complete Registration',
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
