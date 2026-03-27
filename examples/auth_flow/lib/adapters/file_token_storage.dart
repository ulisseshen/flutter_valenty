import '../models/auth_token.dart';
import '../ports/token_storage_port.dart';

/// Real adapter for token storage.
///
/// In a Flutter project this would use `FlutterSecureStorage`:
///
/// ```dart
/// final storage = FlutterSecureStorage();
/// await storage.write(key: 'access_token', value: token.accessToken);
/// ```
///
/// This Dart-only example uses an in-memory map to demonstrate the pattern.
/// The key point: the adapter implements the same port interface as the fake,
/// so you can swap between them without touching the domain layer.
class FileTokenStorage implements TokenStoragePort {
  // In production: FlutterSecureStorage()
  // In this example: simple map (demonstrates the pattern)
  final Map<String, String> _store = {};

  @override
  Future<void> saveToken(AuthToken token) async {
    _store['access_token'] = token.accessToken;
    _store['refresh_token'] = token.refreshToken;
    _store['expires_at'] = token.expiresAt.toIso8601String();
  }

  @override
  Future<AuthToken?> getToken() async {
    if (!_store.containsKey('access_token')) return null;
    return AuthToken(
      accessToken: _store['access_token']!,
      refreshToken: _store['refresh_token']!,
      expiresAt: DateTime.parse(_store['expires_at']!),
    );
  }

  @override
  Future<void> deleteToken() async {
    _store.clear();
  }
}
