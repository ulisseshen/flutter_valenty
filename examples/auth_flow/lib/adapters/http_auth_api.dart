import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth_token.dart';
import '../ports/auth_api_port.dart';

/// Real adapter: calls the auth API over HTTP.
///
/// In a Flutter project you would typically use Dio for interceptors,
/// retry logic, and cancellation support. The `http` package is used
/// here because it works in pure Dart without the Flutter SDK.
class HttpAuthApi implements AuthApiPort {
  HttpAuthApi({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<AuthToken> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw AuthApiException(
        statusCode: response.statusCode,
        message: (body['message'] as String?) ?? 'Login failed',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

/// Exception thrown when the auth API returns a non-200 response.
class AuthApiException implements Exception {
  AuthApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => 'AuthApiException($statusCode): $message';
}
