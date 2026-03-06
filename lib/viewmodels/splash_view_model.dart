import 'package:interview/services/auth_service.dart';
import 'package:interview/views/chat/main_chats_screen.dart';
import 'package:interview/views/splash/splash_screen_two.dart';

class SplashViewModel {
  final AuthService _authService;

  SplashViewModel({AuthService? authService})
      : _authService = authService ?? AuthService();

  Future<String> resolveNextRoute() async {
    try {
      final hasSession = await _authService.hasValidSession();
      return hasSession ? MainChatsScreen.routeName : SplashScreenTwo.routeName;
    } catch (_) {
      return SplashScreenTwo.routeName;
    }
  }
}
