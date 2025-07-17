import 'package:flutter/material.dart';
import '../../auth_service.dart';
import '../../features/auth/phone/phone_auth_screen.dart';
import '../../../universal/theme/gradient_button.dart';

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
      'subtitle': 'Modern tools for education.',
    },
    {
      'title': 'Discover Courses',
      'subtitle': 'Find the best courses and resources for your growth.',
    },
    {
      'title': 'Track Progress',
      'subtitle': 'Monitor your achievements and stay motivated.',
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
      backgroundColor: const Color(0xFF181C23),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _NeonLinesPainter())),
          SafeArea(
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
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF00F6FF,
                                    ).withOpacity(0.7),
                                    blurRadius: 32,
                                    spreadRadius: 8,
                                  ),
                                ],
                                border: Border.all(
                                  color: const Color(0xFF00F6FF),
                                  width: 4,
                                ),
                              ),
                              child: Icon(
                                Icons.auto_stories,
                                color: const Color(0xFF00F6FF),
                                size: 100,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Text(
                              _pages[index]['title']!,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00F6FF),
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    blurRadius: 32,
                                    color: Color(0xFF00F6FF),
                                    offset: Offset(0, 0),
                                  ),
                                  Shadow(
                                    blurRadius: 8,
                                    color: Color(0xFF00F6FF),
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _pages[index]['subtitle']!,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white70,
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
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 24,
                      ),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color:
                            _currentPage == index
                                ? const Color(0xFF00F6FF)
                                : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow:
                            _currentPage == index
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
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 16,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PhoneAuthScreen(),
                          ),
                        );
                      },
                      borderRadius: 24,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Neon lines painter (reuse from OTP screen)
class _NeonLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintCyan =
        Paint()
          ..color = const Color(0xFF00F6FF).withOpacity(0.7)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    final paintMagenta =
        Paint()
          ..color = const Color(0xFFFF00E0).withOpacity(0.7)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    // Top left curve
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(-40, -40), radius: 160),
      0.2,
      1.5,
      false,
      paintCyan,
    );
    // Bottom left curve
    canvas.drawArc(
      Rect.fromCircle(center: Offset(-60, size.height + 60), radius: 180),
      3.8,
      1.5,
      false,
      paintCyan,
    );
    // Top right magenta
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width + 40, 0), radius: 140),
      3.5,
      1.2,
      false,
      paintMagenta,
    );
    // Bottom right magenta
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width + 60, size.height + 60),
        radius: 180,
      ),
      3.8,
      1.5,
      false,
      paintMagenta,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
