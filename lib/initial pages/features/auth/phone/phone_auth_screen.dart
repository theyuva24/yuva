import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'phone_auth_controller.dart';
import '../../../../registration/screens/registration_flow.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../Home screen/home_screen.dart';

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
    if (kDebugMode) print('PhoneAuthScreen initialized at ${DateTime.now()}');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _timer?.cancel();
    if (kDebugMode) print('PhoneAuthScreen disposed at ${DateTime.now()}');
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
    if (kDebugMode)
      print(
        'Starting phone auth with: ${_phoneController.text} at ${DateTime.now()}',
      );
    if (!_formKey.currentState!.validate()) {
      if (kDebugMode) print('Form validation failed at ${DateTime.now()}');
      return;
    }

    String phone = _phoneController.text.trim();

    if (!_isValidPhoneNumber(phone)) {
      _setError('Please enter a valid phone number');
      if (kDebugMode) print('Invalid phone number at ${DateTime.now()}');
      return;
    }

    String formattedPhone = _formatPhoneNumber(phone);
    _currentPhoneNumber = formattedPhone;

    // Start user existence check in parallel
    final userExistenceFuture = FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: formattedPhone)
        .limit(1)
        .get()
        .then((snapshot) => snapshot.docs.isNotEmpty)
        .catchError((_) => false);

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
            if (kDebugMode)
              print('Code sent callback triggered at ${DateTime.now()}');
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
            if (kDebugMode) print('User existence check: $_isExistingUser');
          }
        },
        onError: (error) {
          if (mounted) {
            if (kDebugMode)
              print('Error callback triggered: $error at ${DateTime.now()}');
            setState(() {
              _loading = false;
            });
            _setError(error);
          }
        },
        onAutoVerified: () async {
          if (mounted) {
            if (kDebugMode) print('Auto-verified at ${DateTime.now()}');
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
        if (kDebugMode)
          print(
            'VerifyPhone result failed: ${result['error']} at ${DateTime.now()}',
          );
        setState(() {
          _loading = false;
        });
        _setError(result['error']);
      }
    } catch (e) {
      if (mounted) {
        if (kDebugMode)
          print('Exception in _startPhoneAuth: $e at ${DateTime.now()}');
        setState(() {
          _loading = false;
        });
        _setError('Failed to send OTP: ${e.toString()}');
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (kDebugMode)
      print('Verifying OTP: ${_otpController.text} at ${DateTime.now()}');
    String otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _setError('Please enter the OTP code');
      if (kDebugMode) print('Empty OTP at ${DateTime.now()}');
      return;
    }

    if (otp.length != 6) {
      _setError('OTP must be exactly 6 digits');
      if (kDebugMode)
        print('Invalid OTP length: ${otp.length} at ${DateTime.now()}');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final result = await _controller.signInWithOtp(otp);
      if (kDebugMode)
        print('signInWithOtp result: $result at ${DateTime.now()}');

      if (mounted) {
        if (result['success'] == true) {
          if (kDebugMode) print('Verification successful at ${DateTime.now()}');
          _showSnackBar('Phone number verified successfully!', Colors.green);
          // Ensure user existence check is complete
          if (_isExistingUser == null) {
            _isExistingUser = await FirebaseFirestore.instance
                .collection('users')
                .where('phone', isEqualTo: _currentPhoneNumber)
                .limit(1)
                .get()
                .then((snapshot) => snapshot.docs.isNotEmpty)
                .catchError((_) => false);
            if (kDebugMode)
              print('User existence check (post-OTP): $_isExistingUser');
          }
          _navigateToNextScreen();
        } else {
          if (kDebugMode)
            print(
              'Verification failed: ${result['error']} at ${DateTime.now()}',
            );
          setState(() {
            _loading = false;
          });
          _setError(result['error'] ?? 'Verification failed');
          _otpController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        if (kDebugMode)
          print('Exception in _verifyOtp: $e at ${DateTime.now()}');
        setState(() {
          _loading = false;
        });
        _setError('Verification failed: ${e.toString()}');
        _otpController.clear();
      }
    }
  }

  Future<void> _resendOtp() async {
    if (kDebugMode)
      print('Resending OTP to: $_currentPhoneNumber at ${DateTime.now()}');
    if (_currentPhoneNumber.isEmpty) {
      _setError('Please enter phone number first');
      if (kDebugMode) print('No phone number for resend at ${DateTime.now()}');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });

    try {
      final result = await _controller.resendOtp(_currentPhoneNumber);
      if (kDebugMode) print('Resend result: $result at ${DateTime.now()}');

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
        if (kDebugMode)
          print('Exception in _resendOtp: $e at ${DateTime.now()}');
        setState(() {
          _loading = false;
        });
        _setError('Failed to resend OTP: ${e.toString()}');
      }
    }
  }

  void _setError(String error) {
    if (kDebugMode) print('Setting error: $error at ${DateTime.now()}');
    setState(() {
      _error = error;
      _successMessage = null;
    });
  }

  void _navigateToNextScreen() {
    if (kDebugMode) print('Navigating to next screen at ${DateTime.now()}');
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
    if (kDebugMode) print('Showing snackbar: $message at ${DateTime.now()}');
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
    if (kDebugMode) print('Going back at ${DateTime.now()}');
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
    if (kDebugMode) print('Building PhoneAuthScreen at ${DateTime.now()}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Verification'),
        centerTitle: true,
        elevation: 0,
        leading:
            _codeSent
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _goBack,
                )
                : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(
                  _codeSent ? Icons.message : Icons.phone_android,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 24),
                Text(
                  _codeSent ? 'Enter Verification Code' : 'Enter Phone Number',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _codeSent
                      ? 'We sent a 6-digit code to $_currentPhoneNumber'
                      : 'We\'ll send you a verification code via SMS',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
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
                        const Icon(Icons.error_outline, color: Colors.red),
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
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '9876543210 or +919876543210',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _startPhoneAuth,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _loading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text(
                              'Send OTP',
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Enter OTP',
                      hintText: '123456',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _loading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text(
                              'Verify OTP',
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed:
                        (_resendTimer > 0 || _loading) ? null : _resendOtp,
                    child: Text(
                      _resendTimer > 0
                          ? 'Resend OTP in ${_resendTimer}s'
                          : 'Resend OTP',
                      style: TextStyle(
                        color:
                            (_resendTimer > 0 || _loading) ? Colors.grey : null,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                if (kDebugMode) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Debug Info:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Phone: $_currentPhoneNumber\n'
                    'Code Sent: $_codeSent\n'
                    'Verification ID: ${_controller.verificationId != null ? 'Available' : 'Not Available'}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
