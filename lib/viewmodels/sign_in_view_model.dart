import 'package:interview/services/auth_service.dart';

class SignInViewModel {
  final AuthService _authService;

  SignInViewModel({AuthService? authService})
      : _authService = authService ?? AuthService();

  String? validate({
    required String email,
    required String passcode,
  }) {
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return 'Valid email is required.';
    }

    final onlyDigits = RegExp(r'^\d{6}$');
    if (!onlyDigits.hasMatch(passcode)) {
      return 'Passcode must be exactly 6 digits.';
    }

    return null;
  }

  Future<void> login({
    required String email,
    required String passcode,
  }) {
    return _authService.login(email: email, passcode: passcode);
  }

  Future<void> loginWithGoogle() {
    return _authService.loginWithGoogle();
  }
}
