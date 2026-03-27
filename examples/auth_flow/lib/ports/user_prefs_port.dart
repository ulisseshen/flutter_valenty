import '../models/user.dart';

/// Driven Port: User preferences storage boundary.
///
/// In production, this would be implemented by a SharedPreferences adapter.
/// In tests, a fake implements this with a simple in-memory map.
abstract class UserPrefsPort {
  Future<void> saveUserPrefs(User user);
  Future<User?> getUserPrefs();
  Future<void> clearUserPrefs();
}
