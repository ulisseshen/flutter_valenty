import '../models/auth_token.dart';

/// Driven Port: Authentication API boundary.
///
/// In production, this would be implemented by a Dio-based adapter.
/// In tests, a fake implements this without any HTTP dependency.
abstract class AuthApiPort {
  Future<AuthToken> login(String email, String password);
}
