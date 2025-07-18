import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/registration_controller.dart';
import 'step1_personal_info.dart';
import 'step2_education_info.dart';
import 'step3_interests.dart';
import '../../initial pages/auth_service.dart';
import '../../universal/theme/app_theme.dart';

/// Registration flow after phone auth
class RegistrationFlow extends StatelessWidget {
  final dynamic userDetails; // dynamic to avoid Pigeon crash

  const RegistrationFlow({super.key, this.userDetails});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final isAuthenticated = authService.isUserAuthenticated();

    return ChangeNotifierProvider(
      create: (_) => RegistrationController(),
      child: Consumer<RegistrationController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(
              leading:
                  controller.currentStep > 0
                      ? IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppThemeLight.primary,
                        ),
                        onPressed: () {
                          controller.prevStep();
                        },
                      )
                      : null,
              backgroundColor: AppThemeLight.surface,
              title: Text(
                isAuthenticated ? 'Complete Registration' : 'Create Account',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppThemeLight.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              centerTitle: true,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppThemeLight.primary),
            ),
            backgroundColor: AppThemeLight.background,
            body: Column(
              children: [
                const SizedBox(height: 16),
                _StepProgress(currentStep: controller.currentStep),
                const SizedBox(height: 16),
                Expanded(
                  child: IndexedStack(
                    index: controller.currentStep,
                    children: const [
                      Step1PersonalInfo(),
                      Step2EducationInfo(),
                      Step3Interests(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  final int currentStep;
  const _StepProgress({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 32,
          height: 8,
          decoration: BoxDecoration(
            color:
                i <= currentStep ? AppThemeLight.primary : AppThemeLight.border,
            borderRadius: BorderRadius.circular(4),
            boxShadow:
                i == currentStep
                    ? [
                      const BoxShadow(
                        color: AppThemeLight.primary,
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                    : [],
          ),
        );
      }),
    );
  }
}
