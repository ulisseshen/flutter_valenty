import 'package:auth_flow_example/models/auth_token.dart';
import 'package:auth_flow_example/ports/auth_api_port.dart';

/// AI-generated fake for AuthApiPort.
///
/// Replaces Dio HTTP calls with configurable in-memory responses.
/// No network. No serialization. Pure domain logic testing.
class FakeAuthApi implements AuthApiPort {
  AuthToken? _successResponse;
  int? _errorStatusCode;
  String? _errorMessage;

  /// Configure a successful login response.
  void setSuccessResponse({
    required String accessToken,
    String refreshToken = 'default-refresh',
    DateTime? expiresAt,
  }) {
    _successResponse = AuthToken(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt ?? DateTime.now().add(const Duration(hours: 1)),
    );
    _errorStatusCode = null;
    _errorMessage = null;
  }

  /// Configure an error response.
  void setErrorResponse({
    required int statusCode,
    required String message,
  }) {
    _successResponse = null;
    _errorStatusCode = statusCode;
    _errorMessage = message;
  }

  /// Synchronous login for use in test builders.
  ///
  /// Since fakes hold in-memory state, there is no real I/O.
  /// The When builder calls this directly to avoid async gaps.
  AuthToken loginSync(String email, String password) {
    if (_errorStatusCode != null) {
      throw AuthApiException(
        statusCode: _errorStatusCode!,
        message: _errorMessage ?? 'Unknown error',
      );
    }
    if (_successResponse != null) {
      return _successResponse!;
    }
    throw StateError('FakeAuthApi not configured. Call setSuccessResponse() '
        'or setErrorResponse() first.');
  }

  @override
  Future<AuthToken> login(String email, String password) async {
    return loginSync(email, password);
  }
}

/// Exception thrown by the auth API on failure.
class AuthApiException implements Exception {
  const AuthApiException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => 'AuthApiException($statusCode): $message';
}
