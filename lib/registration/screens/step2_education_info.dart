import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/registration_controller.dart';
import '../widgets/id_card_picker.dart';

class Step2EducationInfo extends StatelessWidget {
  const Step2EducationInfo({super.key});

  static const List<String> years = ['1st', '2nd', 'Graduate'];

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<RegistrationController>(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              initialValue: controller.data.college,
              decoration: const InputDecoration(
                labelText: 'College / Institution',
                border: OutlineInputBorder(),
              ),
              onChanged: controller.updateCollege,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: controller.data.year,
              items:
                  years
                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
              onChanged: (val) {
                if (val != null) controller.updateYear(val);
              },
              decoration: const InputDecoration(
                labelText: 'Current Year',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            IdCardPicker(
              imagePath: controller.data.idCardPath,
              onImagePicked: controller.updateIdCard,
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: controller.data.course,
              decoration: const InputDecoration(
                labelText: 'Course',
                border: OutlineInputBorder(),
              ),
              onChanged: controller.updateCourse,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
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
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
