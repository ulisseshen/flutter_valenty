import 'package:auth_flow_example/models/user.dart';
import 'package:auth_flow_example/ports/user_prefs_port.dart';

/// AI-generated fake for UserPrefsPort.
///
/// Replaces SharedPreferences with a simple in-memory map.
/// No disk I/O. No platform channels. Pure domain logic testing.
class FakeUserPrefs implements UserPrefsPort {
  User? _storedUser;

  /// Access the stored user directly (for test assertions).
  User? get storedUser => _storedUser;

  /// Synchronous save for use in test builders.
  void saveUserPrefsSync(User user) {
    _storedUser = user;
  }

  @override
  Future<void> saveUserPrefs(User user) async {
    saveUserPrefsSync(user);
  }

  @override
  Future<User?> getUserPrefs() async {
    return _storedUser;
  }

  @override
  Future<void> clearUserPrefs() async {
    _storedUser = null;
  }
}
