import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/registration_controller.dart';
import 'step1_personal_info.dart';
import 'step2_education_info.dart';
import 'step3_interests.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

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
                          color: Color(0xFF00F6FF),
                        ),
                        onPressed: () {
                          controller.prevStep();
                        },
                      )
                      : null,
              backgroundColor: const Color(0xFF181C23),
              title: Text(
                isAuthenticated ? 'Complete Registration' : 'Create Account',
                style: const TextStyle(
                  color: Color(0xFF00F6FF),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 22,
                  shadows: [
                    Shadow(
                      blurRadius: 16,
                      color: Color(0xFF00F6FF),
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF00F6FF)),
            ),
            backgroundColor: const Color(0xFF181C23),
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
            color: i <= currentStep ? const Color(0xFF00F6FF) : Colors.white24,
            borderRadius: BorderRadius.circular(4),
            boxShadow:
                i == currentStep
                    ? [
                      const BoxShadow(
                        color: Color(0xFF00F6FF),
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
