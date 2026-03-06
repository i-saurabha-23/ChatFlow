import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:interview/core/constants/app_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'chatflow_access_token';
  static String? _inMemoryToken;
  static bool _googleInitialized = false;

  Future<bool> hasValidSession() async {
    final response = await _authorizedGet(AppEndpoints.session);

    if (response.statusCode == 200) {
      return true;
    }

    await clearToken();
    return false;
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String passcode,
    String? phoneNumber,
  }) async {
    final response = await http.post(
      Uri.parse(AppEndpoints.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': passcode,
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          'phoneNumber': phoneNumber.trim(),
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(_extractErrorMessage(response, 'Registration failed.'));
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final token = decoded['token']?.toString();

    if (token == null || token.isEmpty) {
      throw Exception('Missing token in register response.');
    }

    await saveToken(token);
  }

  Future<void> login({
    required String email,
    required String passcode,
  }) async {
    final response = await http.post(
      Uri.parse(AppEndpoints.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': passcode,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(_extractErrorMessage(response, 'Login failed.'));
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final token = decoded['token']?.toString();

    if (token == null || token.isEmpty) {
      throw Exception('Missing token in login response.');
    }

    await saveToken(token);
  }

  Future<void> loginWithGoogle() async {
    try {
      final serverClientId = _resolveGoogleServerClientId();
      if (serverClientId == null || serverClientId.isEmpty) {
        throw Exception(
          'Google is not configured for Android. Run with --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>.apps.googleusercontent.com',
        );
      }

      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize(
          clientId: kIsWeb && AppEndpoints.googleWebClientId.isNotEmpty
              ? AppEndpoints.googleWebClientId
              : null,
          serverClientId: serverClientId,
        );
        _googleInitialized = true;
      }

      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw Exception('Google sign-in is not supported on this platform.');
      }

      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google ID token not available. Provide GOOGLE_WEB_CLIENT_ID via --dart-define.',
        );
      }

      final response = await http.post(
        Uri.parse(AppEndpoints.googleLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode != 201) {
        throw Exception(_extractErrorMessage(response, 'Google sign-in failed.'));
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final token = decoded['token']?.toString();

      if (token == null || token.isEmpty) {
        throw Exception('Missing token in Google login response.');
      }

      await saveToken(token);
    } on GoogleSignInException catch (error) {
      throw Exception('Google sign-in failed: ${error.description ?? error.code.name}.');
    } on MissingPluginException {
      throw Exception(
        'Google Sign-In plugin is not registered. Run flutter clean and reinstall the app.',
      );
    }
  }

  String? _resolveGoogleServerClientId() {
    if (AppEndpoints.googleServerClientId.isNotEmpty) {
      return AppEndpoints.googleServerClientId;
    }
    if (AppEndpoints.googleWebClientId.isNotEmpty) {
      return AppEndpoints.googleWebClientId;
    }
    return null;
  }

  Future<void> saveToken(String token) async {
    _inMemoryToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } on MissingPluginException {
      // Fallback for environments where shared_preferences is not registered.
    }
  }

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey) ?? _inMemoryToken;
    } on MissingPluginException {
      return _inMemoryToken;
    }
  }

  Future<void> clearToken() async {
    _inMemoryToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } on MissingPluginException {
      // Fallback for environments where shared_preferences is not registered.
    }
  }

  String _extractErrorMessage(http.Response response, String fallbackMessage) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final rawMessage = decoded['message'];

      if (rawMessage is List && rawMessage.isNotEmpty) {
        return rawMessage.first.toString();
      }

      if (rawMessage != null) {
        return rawMessage.toString();
      }

      return fallbackMessage;
    } catch (_) {
      return fallbackMessage;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _authorizedGet(AppEndpoints.session);
    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response, 'Failed to fetch session.'));
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final user = decoded['user'];
    if (user is! Map<String, dynamic>) {
      throw Exception('Session response is missing user.');
    }
    return user;
  }

  Future<Map<String, String>> authorizedJsonHeaders() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Missing auth token. Please sign in again.');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _authorizedGet(String url) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      return http.Response('{"message":"Missing auth token."}', 401);
    }

    return http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
