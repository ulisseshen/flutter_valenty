import 'package:auth_flow_example/models/auth_token.dart';
import 'package:auth_flow_example/ports/token_storage_port.dart';

/// AI-generated fake for TokenStoragePort.
///
/// Replaces FlutterSecureStorage with a simple in-memory map.
/// No encryption. No platform channels. Pure domain logic testing.
class FakeTokenStorage implements TokenStoragePort {
  AuthToken? _storedToken;

  /// Access the stored token directly (for test assertions).
  AuthToken? get storedToken => _storedToken;

  /// Synchronous save for use in test builders.
  void saveTokenSync(AuthToken token) {
    _storedToken = token;
  }

  @override
  Future<void> saveToken(AuthToken token) async {
    saveTokenSync(token);
  }

  @override
  Future<AuthToken?> getToken() async {
    return _storedToken;
  }

  @override
  Future<void> deleteToken() async {
    _storedToken = null;
  }
}
