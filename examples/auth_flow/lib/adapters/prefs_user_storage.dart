import '../models/user.dart';
import '../ports/user_prefs_port.dart';

/// Real adapter for user preferences.
///
/// In a Flutter project this would use `SharedPreferences`:
///
/// ```dart
/// final prefs = await SharedPreferences.getInstance();
/// await prefs.setString('user_email', user.email);
/// ```
///
/// This Dart-only example uses an in-memory map to demonstrate the pattern.
/// The key point: the adapter implements the same port interface as the fake,
/// so you can swap between them without touching the domain layer.
class PrefsUserStorage implements UserPrefsPort {
  // In production: SharedPreferences.getInstance()
  // In this example: simple map (demonstrates the pattern)
  final Map<String, String> _prefs = {};

  @override
  Future<void> saveUserPrefs(User user) async {
    _prefs['user_id'] = user.id;
    _prefs['user_email'] = user.email;
    _prefs['user_name'] = user.name;
  }

  @override
  Future<User?> getUserPrefs() async {
    if (!_prefs.containsKey('user_id')) return null;
    return User(
      id: _prefs['user_id']!,
      email: _prefs['user_email']!,
      name: _prefs['user_name']!,
    );
  }

  @override
  Future<void> clearUserPrefs() async {
    _prefs.clear();
  }
}
