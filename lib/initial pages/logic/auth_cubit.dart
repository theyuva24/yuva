import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  String? _verificationId;

  AuthCubit(this._authRepository) : super(AuthInitial());

  void verifyPhone(String phone) async {
    emit(AuthLoading());
    await _authRepository.verifyPhoneNumber(
      phoneNumber: phone,
      codeSent: (verificationId, resendToken) {
        _verificationId = verificationId;
        emit(AuthCodeSent(verificationId));
      },
      verificationFailed: (e) {
        emit(AuthError(e.message ?? 'Verification failed'));
      },
      codeAutoRetrievalTimeout: (verificationId) {
        _verificationId = verificationId;
      },
      verificationCompleted: (credential) async {
        try {
          await _authRepository.signInWithCredential(credential);
          emit(AuthVerified());
        } catch (e) {
          emit(AuthError('Auto verification failed'));
        }
      },
    );
  }

  void submitOTP(String otp) async {
    if (_verificationId == null) {
      emit(AuthError('No verification ID'));
      return;
    }
    emit(AuthLoading());
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _authRepository.signInWithCredential(credential);
      emit(AuthVerified());
    } catch (e) {
      emit(AuthError('Invalid OTP'));
    }
  }
}
