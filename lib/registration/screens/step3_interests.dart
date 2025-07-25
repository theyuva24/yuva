import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/registration_controller.dart';
import '../../universal/screens/home_screen.dart';
import '../../universal/theme/app_theme.dart';
import '../widgets/interests_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Choose your interests (max 5):',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 16.h),
            InterestsPicker(
              initialSelected: selected,
              onChanged: (newInterests) {
                controller.updateInterests(newInterests);
              },
              maxSelection: 5,
            ),
            SizedBox(height: 32.h),
            if (controller.isLoading)
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            GradientButton(
              text: 'Create My Account',
              onTap:
                  controller.isLoading
                      ? () {}
                      : () async {
                        if (controller.data.interests.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please select at least one interest',
                              ),
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
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
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
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
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                            ),
                          );
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const HomeScreen(),
                            ),
                          );
                        }
                      },
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
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16.h),
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 24.h),
            Text(
              'Setting up your profile...',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
