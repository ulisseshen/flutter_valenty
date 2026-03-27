import 'package:meta/meta.dart';

import 'http_client.dart';

/// God class: AuthManager with static chain access pattern.
///
/// BAD: Handles login, token storage, profile, all in one class.
/// BAD: Static singleton access — `AuthManager.instance.currentUserId!`
class AuthManager {
  static final instance = AuthManager._();
  AuthManager._();

  String? _currentUserId;
  String? _currentUserEmail;
  String? _authToken;

  // BAD: Static chain access pattern
  String? get currentUserId => _currentUserId;
  String? get currentUserEmail => _currentUserEmail;
  String? get authToken => _authToken;

  // BAD: Handles login, token storage, profile, all in one class
  Future<void> login(String email, String password) async {
    final client = RealHttpClient();
    final response = await client.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    _currentUserId = (response as Map<String, dynamic>)['userId'] as String;
    _currentUserEmail = email;
    _authToken = response['token'] as String;
  }

  void logout() {
    _currentUserId = null;
    _currentUserEmail = null;
    _authToken = null;
  }

  bool get isLoggedIn => _currentUserId != null;

  @visibleForTesting
  void setForTesting({String? userId, String? email, String? token}) {
    _currentUserId = userId;
    _currentUserEmail = email;
    _authToken = token;
  }

  @visibleForTesting
  void resetForTesting() {
    _currentUserId = null;
    _currentUserEmail = null;
    _authToken = null;
  }
}
