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
import 'package:yuva/universal/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../../profile/terms_and_conditions_page.dart';
import '../../../../profile/privacy_policy_page.dart';

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
            _showSnackBar(
              'OTP sent successfully!',
              Theme.of(context).colorScheme.secondary,
            );
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
            _showSnackBar(
              'Phone number verified automatically!',
              Theme.of(context).colorScheme.secondary,
            );
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
          _showSnackBar(
            'Phone number verified successfully!',
            Theme.of(context).colorScheme.secondary,
          );
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
          _showSnackBar(
            'OTP resent successfully!',
            Theme.of(context).colorScheme.secondary,
          );
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    Center(
                      child: Text(
                        'YUVA',
                        style: GoogleFonts.orbitron(
                          textStyle: theme.textTheme.displaySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(76),
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
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
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
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
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
                          color: Theme.of(
                            context,
                          ).colorScheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (!_codeSent) ...[
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9+\-\s]'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter your phone number',
                          prefixIcon: Icon(
                            Icons.phone,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        style: theme.textTheme.bodyLarge,
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
                      const SizedBox(height: 32),
                      GradientButton(
                        text: 'SEND OTP',
                        onTap: _loading ? () {} : _startPhoneAuth,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              Text(
                                'By continuing, you agree to YUVA’s ',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const TermsAndConditionsPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Terms & Conditions',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                ' and ',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const PrivacyPolicyPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                '.',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
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
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sent to $_currentPhoneNumber',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
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
                          activeColor: Theme.of(context).colorScheme.primary,
                          selectedColor:
                              Theme.of(context).colorScheme.secondary,
                          inactiveColor: Theme.of(context).dividerColor,
                          activeFillColor: Colors.transparent,
                          selectedFillColor: Colors.transparent,
                          inactiveFillColor: Colors.transparent,
                          borderWidth: 2,
                        ),
                        textStyle: theme.textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
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
                        text: 'VERIFY',
                        onTap: _loading ? () {} : _verifyOtp,
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
                                ? 'Resend code in 00: ${_resendTimer.toString().padLeft(2, '0')}'
                                : 'Resend code',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
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
            if (_loading)
              Container(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
