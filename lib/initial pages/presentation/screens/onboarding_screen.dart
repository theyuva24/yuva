import 'package:flutter/material.dart';
import '../../auth_service.dart';
import '../../features/auth/phone/phone_auth_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../universal/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  final AuthService _authService = AuthService();

  final List<Map<String, String>> _pages = [
    {
      'title': 'Empowering your learning journey',
      'subtitle': 'India’s youth hub for learning, networking, and growth.',
    },
    {
      'title': 'Discover Courses',
      'subtitle': 'Compete in challenges and track your progress with ease.',
    },
    {
      'title': 'Track Progress',
      'subtitle': 'Join student hubs, share ideas, and grow your community.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Check if user is authenticated but not fully registered
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isAuthenticatedButNotRegistered =
          await _authService.isUserAuthenticatedButNotRegistered();
      if (isAuthenticatedButNotRegistered && mounted) {
        // Show a message that they need to complete registration
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete your registration to continue'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppThemeLight.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.all(32.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180.w,
                          height: 180.w,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppThemeLight.primary.withAlpha(51),
                                blurRadius: 32.r,
                                spreadRadius: 8.r,
                              ),
                            ],
                            border: Border.all(
                              color: AppThemeLight.primary,
                              width: 4.w,
                            ),
                          ),
                          child: Icon(
                            Icons.auto_stories,
                            color: AppThemeLight.primary,
                            size: 100.sp,
                          ),
                        ),
                        SizedBox(height: 40.h),
                        Text(
                          _pages[index]['title']!,
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: AppThemeLight.primary,
                            letterSpacing: 2.w,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          _pages[index]['subtitle']!,
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: AppThemeLight.textDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 24.h),
                  width: _currentPage == index ? 24.w : 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color:
                        _currentPage == index
                            ? AppThemeLight.primary
                            : Colors.white24,
                    borderRadius: BorderRadius.circular(4.r),
                    boxShadow:
                        _currentPage == index
                            ? [
                              BoxShadow(
                                color: AppThemeLight.primary.withAlpha(51),
                                blurRadius: 12.r,
                                spreadRadius: 2.r,
                              ),
                            ]
                            : [],
                  ),
                );
              }),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
              child: SizedBox(
                width: double.infinity,
                child: GradientButton(
                  text: 'Get Started',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PhoneAuthScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
