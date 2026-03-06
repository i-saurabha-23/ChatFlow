class AppEndpoints {
  const AppEndpoints._();

  // Use 10.0.2.2 for Android emulator to reach local machine.
  static const String baseUrl = 'https://fsh60pfq-3000.inc1.devtunnels.ms/api';

  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';
  static const String googleLogin = '$baseUrl/auth/google';
  static const String session = '$baseUrl/auth/session';
  static const String users = '$baseUrl/users';
  static const String groups = '$baseUrl/groups';
  static const String directMessages = '$baseUrl/messages/direct';
  static const String groupMessages = '$baseUrl/messages/group';

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
}
