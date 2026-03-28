import 'package:valenty_test/valenty_test.dart';

import 'login_when_builder.dart';

/// WhenBuilder for the Authentication feature.
///
/// Provides use cases available in the When phase:
/// - `.login()` — execute the login use case
class AuthWhenBuilder extends WhenBuilder {
  AuthWhenBuilder(super.scenario);

  /// Trigger the "login" use case.
  LoginWhenBuilder login() => LoginWhenBuilder(scenario);
}
