import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'phone_auth_controller.dart';
import '../../../../registration/screens/registration_flow.dart';
import '../../../auth_service.dart';
import '../../../../universal/screens/home_screen.dart';
import 'package:yuva/universal/theme/gradient_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _controller = PhoneAuthController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _otpFocusNode = FocusNode();

  bool _codeSent = false;
  bool _loading = false;
  bool _autoVerified = false;
  String? _error;
  String? _successMessage;
  int _resendTimer = 0;
  Timer? _timer;
  String _currentPhoneNumber = '';
  bool? _isExistingUser; // null = not checked yet

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _resendTimer = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendTimer--;
        });
        if (_resendTimer <= 0) {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  String _formatPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.startsWith('91') && cleanPhone.length == 12) {
      return '+$cleanPhone';
    } else if (cleanPhone.length == 10) {
      return '+91$cleanPhone';
    } else if (cleanPhone.startsWith('0') && cleanPhone.length == 11) {
      return '+91${cleanPhone.substring(1)}';
    } else if (phone.startsWith('+')) {
      return phone;
    } else {
      return '+91$cleanPhone';
    }
  }

  bool _isValidPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.length == 10) return true;
    if (phone.startsWith('+') &&
        cleanPhone.length >= 10 &&
        cleanPhone.length <= 15) {
      return true;
    }
    return false;
  }

  Future<void> _startPhoneAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    String phone = _phoneController.text.trim();

    if (!_isValidPhoneNumber(phone)) {
      _setError('Please enter a valid phone number');
      return;
    }

    String formattedPhone = _formatPhoneNumber(phone);
    _currentPhoneNumber = formattedPhone;

    // Start user existence check in parallel using AuthService
    final authService = AuthService();
    final userExistenceFuture = authService.doesUserExistByPhone(
      formattedPhone,
    );

    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final result = await _controller.verifyPhone(
        formattedPhone,
        onCodeSent: (message) async {
          if (mounted) {
            setState(() {
              _codeSent = true;
              _loading = false;
              _successMessage = message;
            });
            _startResendTimer();
            _showSnackBar('OTP sent successfully!', Colors.green);
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _otpFocusNode.requestFocus();
              }
            });
            // Await user existence check result
            _isExistingUser = await userExistenceFuture;
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _loading = false;
            });
            _setError(error);
          }
        },
        onAutoVerified: () async {
          if (mounted) {
            setState(() {
              _autoVerified = true;
            });
            _showSnackBar('Phone number verified automatically!', Colors.green);
            // Await user existence check result if not already done
            _isExistingUser ??= await userExistenceFuture;
            _navigateToNextScreen();
          }
        },
      );

      if (mounted && !result['success']) {
        setState(() {
          _loading = false;
        });
        _setError(result['error']);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        _setError('Failed to send OTP:  e.toString()');
      }
    }
  }

  Future<void> _verifyOtp() async {
    String otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _setError('Please enter the OTP code');
      return;
    }

    if (otp.length != 6) {
      _setError('OTP must be exactly 6 digits');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final result = await _controller.signInWithOtp(otp);

      if (mounted) {
        if (result['success'] == true) {
          _showSnackBar('Phone number verified successfully!', Colors.green);
          // Ensure user existence check is complete
          if (_isExistingUser == null) {
            final authService = AuthService();
            _isExistingUser = await authService.doesUserExistByPhone(
              _currentPhoneNumber,
            );
          }
          _navigateToNextScreen();
        } else {
          setState(() {
            _loading = false;
          });
          _setError(result['error'] ?? 'Verification failed');
          _otpController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        _setError('Verification failed:  e.toString()');
        _otpController.clear();
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_currentPhoneNumber.isEmpty) {
      _setError('Please enter phone number first');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final result = await _controller.resendOtp(_currentPhoneNumber);

      if (mounted) {
        if (result['success']) {
          _startResendTimer();
          _showSnackBar('OTP resent successfully!', Colors.green);
        } else {
          _setError(result['error']);
        }
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        _setError('Failed to resend OTP:  e.toString()');
      }
    }
  }

  void _setError(String error) {
    setState(() {
      _error = error;
      _successMessage = null;
    });
  }

  void _navigateToNextScreen() {
    if (mounted) {
      if (_isExistingUser == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RegistrationFlow()),
        );
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _goBack() {
    setState(() {
      _codeSent = false;
      _otpController.clear();
      _error = null;
      _successMessage = null;
      _loading = false;
    });
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181C23),
      body: Stack(
        children: [
          // Neon lines background
          Positioned.fill(child: CustomPaint(painter: _NeonLinesPainter())),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Neon YUVA logo
                    Center(
                      child: Text(
                        'YUVA',
                        style: GoogleFonts.orbitron(
                          textStyle: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00F6FF),
                            letterSpacing: 4,
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Login to explore opportunities',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    if (_successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!_codeSent) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF232733),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF00F6FF).withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF181C23),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(10),
                              child: const Icon(
                                Icons.phone,
                                color: Color(0xFF00F6FF),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9+\-\s]'),
                                  ),
                                ],
                                decoration: const InputDecoration(
                                  labelText: null,
                                  hintText: 'Enter your phone number',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your phone number';
                                  }
                                  if (!_isValidPhoneNumber(value.trim())) {
                                    return 'Please enter a valid phone number';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  if (_error != null) {
                                    setState(() {
                                      _error = null;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 56,
                        child: GradientButton(
                          onPressed: _loading ? null : _startPhoneAuth,
                          borderRadius: 16,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00FF85), // green
                              Color(0xFF00F6FF), // cyan
                              Color(0xFF00B2FF), // blue
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          child:
                              _loading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                  : const Text(
                                    'SEND OTP',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Enter the OTP code',
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sent to $_currentPhoneNumber',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      PinCodeTextField(
                        appContext: context,
                        length: 6,
                        controller: _otpController,
                        focusNode: _otpFocusNode,
                        autoFocus: true,
                        keyboardType: TextInputType.number,
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(16),
                          fieldHeight: 60,
                          fieldWidth: 50,
                          activeColor: Color(0xFF00F6FF),
                          selectedColor: Color(0xFF00F6FF),
                          inactiveColor: Colors.white24,
                          activeFillColor: Colors.transparent,
                          selectedFillColor: Colors.transparent,
                          inactiveFillColor: Colors.transparent,
                          borderWidth: 2,
                        ),
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 16,
                              color: Color(0xFF00F6FF),
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                        enableActiveFill: false,
                        onChanged: (value) {
                          if (_error != null) {
                            setState(() {
                              _error = null;
                            });
                          }
                          if (value.length == 6) {
                            _verifyOtp();
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                      GradientButton(
                        onPressed: _loading ? null : _verifyOtp,
                        borderRadius: 24,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF00FF85),
                            Color(0xFF00F6FF),
                            Color(0xFF00B2FF),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        child:
                            _loading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                                : const Text(
                                  'VERIFY',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed:
                              (_resendTimer > 0 || _loading)
                                  ? null
                                  : _resendOtp,
                          child: Text(
                            _resendTimer > 0
                                ? 'Resend code in 00:${_resendTimer.toString().padLeft(2, '0')}'
                                : 'Resend code',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Neon lines painter
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
