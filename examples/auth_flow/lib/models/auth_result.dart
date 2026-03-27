import 'auth_token.dart';
import 'user.dart';

class AuthResult {
  const AuthResult({
    required this.success,
    this.user,
    this.token,
    this.errorMessage,
  });

  final bool success;
  final User? user;
  final AuthToken? token;
  final String? errorMessage;
}
