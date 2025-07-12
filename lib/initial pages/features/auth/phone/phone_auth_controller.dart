import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PhoneAuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;

  String? get verificationId => _verificationId;
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<Map<String, dynamic>> verifyPhone(
      String phoneNumber, {
        required Function(String) onCodeSent,
        required Function(String) onError,
        Function()? onAutoVerified,
      }) async {
    try {
      if (kDebugMode) print('verifyPhone called with: $phoneNumber at ${DateTime.now()}');
      _verificationId = null;

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            if (kDebugMode) print('Verification completed for: $phoneNumber');
            final userCredential = await _auth.signInWithCredential(credential);
            if (kDebugMode) {
              print('Auto-verified user: ${userCredential.user?.phoneNumber} at ${DateTime.now()}');
            }
            onAutoVerified?.call();
          } catch (e) {
            if (kDebugMode) print('Auto-verification error: $e at ${DateTime.now()}');
            onError('Auto-verification failed: ${e.toString()}');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (kDebugMode) print('Verification failed: ${e.code} - ${e.message} at ${DateTime.now()}');
          String errorMessage = _getErrorMessage(e);
          onError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          if (kDebugMode) print('Code sent. Verification ID: $verificationId at ${DateTime.now()}');
          onCodeSent('OTP sent successfully to $phoneNumber');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          if (kDebugMode) print('Code auto-retrieval timeout at ${DateTime.now()}');
        },
      );

      return {'success': true, 'message': 'OTP request sent successfully'};
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('FirebaseAuthException: ${e.code} - ${e.message} at ${DateTime.now()}');
      return {'success': false, 'error': _getErrorMessage(e)};
    } catch (e) {
      if (kDebugMode) print('Generic error: $e at ${DateTime.now()}');
      return {'success': false, 'error': 'An unexpected error occurred: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> signInWithOtp(String smsCode) async {
    try {
      if (kDebugMode) print('signInWithOtp called with smsCode: $smsCode at ${DateTime.now()}');
      if (_verificationId == null) {
        if (kDebugMode) print('No verification ID found at ${DateTime.now()}');
        return {'success': false, 'error': 'No verification ID found. Please request OTP again.'};
      }

      if (smsCode.trim().isEmpty) {
        if (kDebugMode) print('Empty SMS code at ${DateTime.now()}');
        return {'success': false, 'error': 'Please enter the OTP code.'};
      }

      if (smsCode.trim().length != 6) {
        if (kDebugMode) print('Invalid OTP length: ${smsCode.length} at ${DateTime.now()}');
        return {'success': false, 'error': 'OTP must be exactly 6 digits.'};
      }

      final cleanSmsCode = smsCode.trim().replaceAll(RegExp(r'[^\d]'), '');

      if (kDebugMode) print('Verifying OTP: $cleanSmsCode with verificationId: $_verificationId');
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: cleanSmsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (kDebugMode) print('Sign-in successful for: ${userCredential.user?.phoneNumber} at ${DateTime.now()}');

      return {
        'success': true,
        'message': 'Phone number verified successfully!',
        'user': userCredential.user
      };
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('OTP verification failed: ${e.code} - ${e.message} at ${DateTime.now()}');
      return {'success': false, 'error': _getErrorMessage(e)};
    } catch (e) {
      if (kDebugMode) print('Generic sign-in error: $e at ${DateTime.now()}');
      return {'success': false, 'error': 'Sign-in failed: ${e.toString()}'};
    }
  }

  Future<void> signOut() async {
    try {
      if (kDebugMode) print('Signing out at ${DateTime.now()}');
      await _auth.signOut();
      _verificationId = null;
      _resendToken = null;
      if (kDebugMode) print('User signed out successfully at ${DateTime.now()}');
    } catch (e) {
      if (kDebugMode) print('Sign out error: ${e.toString()} at ${DateTime.now()}');
    }
  }

  Future<Map<String, dynamic>> resendOtp(String phoneNumber) async {
    if (kDebugMode) print('Resending OTP to: $phoneNumber at ${DateTime.now()}');
    return await verifyPhone(
      phoneNumber,
      onCodeSent: (message) {
        if (kDebugMode) print('OTP resent successfully at ${DateTime.now()}');
      },
      onError: (error) {
        if (kDebugMode) print('Failed to resend OTP: $error at ${DateTime.now()}');
      },
    );
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number format is invalid. Please check and try again.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'invalid-verification-code':
        return 'Invalid OTP code. Please check the code and try again.';
      case 'session-expired':
        return 'The verification session has expired. Please request a new OTP.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';
      case 'app-not-authorized':
        return 'This app is not authorized to use Firebase Authentication. Please contact support.';
      case 'missing-phone-number':
        return 'Phone number is required.';
      case 'invalid-app-credential':
        return 'Invalid app credential. Please check your Firebase configuration.';
      case 'credential-already-in-use':
        return 'This phone number is already associated with another account.';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled. Please enable it in Firebase Console.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'web-context-already-presented':
        return 'Another verification process is already in progress.';
      case 'web-context-cancelled':
        return 'Verification process was cancelled.';
      default:
        return e.message ?? 'An error occurred during authentication. Please try again.';
    }
  }
}