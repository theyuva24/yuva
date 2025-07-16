import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/registration_controller.dart';
import '../../Home screen/home_screen.dart';
import '../../core/theme/gradient_button.dart';
import '../widgets/interests_picker.dart';

class Step3Interests extends StatefulWidget {
  const Step3Interests({super.key});

  @override
  State<Step3Interests> createState() => _Step3InterestsState();
}

class _Step3InterestsState extends State<Step3Interests> {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<RegistrationController>(context);
    final selected = controller.data.interests;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose your interests (max 5):',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF00F6FF),
              ),
            ),
            const SizedBox(height: 16),
            InterestsPicker(
              initialSelected: selected,
              onChanged: (newInterests) {
                controller.updateInterests(newInterests);
              },
              maxSelection: 5,
            ),
            const SizedBox(height: 32),
            GradientButton(
              onPressed:
                  controller.isLoading
                      ? null
                      : () async {
                        if (controller.data.interests.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select at least one interest',
                              ),
                            ),
                          );
                          return;
                        }
                        // Show animation dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (ctx) => const _ProfileSetupDialog(),
                        );

                        try {
                          final error = await controller.submitRegistration(
                            context,
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).pop(); // Close animation dialog

                          if (error == null) {
                            // Navigate to our actual home screen
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                            );
                          } else {
                            // Even if Firebase fails, still navigate to home screen
                            // but show a warning
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Profile created! Some data may not be saved due to network issues.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const HomeScreen(),
                              ),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          Navigator.of(context).pop(); // Close animation dialog

                          // Navigate to home screen even if there's an error
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Profile created! Some data may not be saved due to network issues.',
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const HomeScreen(),
                            ),
                          );
                        }
                      },
              child:
                  controller.isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Create My Account',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSetupDialog extends StatelessWidget {
  const _ProfileSetupDialog();
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(height: 16),
            CircularProgressIndicator(color: Color(0xFF6C63FF)),
            SizedBox(height: 24),
            Text(
              'Setting up your profile...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
