import 'package:interview/services/auth_service.dart';

class SignUpViewModel {
  final AuthService _authService;

  SignUpViewModel({AuthService? authService})
      : _authService = authService ?? AuthService();

  String? validate({
    required String name,
    required String email,
    required String passcode,
  }) {
    if (name.trim().isEmpty) {
      return 'Name is required.';
    }

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

  Future<void> register({
    required String name,
    required String email,
    required String passcode,
    String? phoneNumber,
  }) {
    return _authService.register(
      fullName: name.trim(),
      email: email.trim(),
      passcode: passcode,
      phoneNumber: phoneNumber,
    );
  }

  Future<void> loginWithGoogle() {
    return _authService.loginWithGoogle();
  }
}
