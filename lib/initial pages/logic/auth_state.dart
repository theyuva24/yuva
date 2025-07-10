abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthCodeSent extends AuthState {
  final String verificationId;
  AuthCodeSent(this.verificationId);
}

class AuthVerified extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
