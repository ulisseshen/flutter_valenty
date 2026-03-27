import '../models/auth_token.dart';

/// Driven Port: Secure token storage boundary.
///
/// In production, this would be implemented by a FlutterSecureStorage adapter.
/// In tests, a fake implements this with a simple in-memory map.
abstract class TokenStoragePort {
  Future<void> saveToken(AuthToken token);
  Future<AuthToken?> getToken();
  Future<void> deleteToken();
}
