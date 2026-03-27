import 'package:valenty_dsl/valenty_dsl.dart';

import 'api_response_given_builder.dart';
import 'credentials_given_builder.dart';

/// GivenBuilder for the Authentication feature.
///
/// Provides domain objects available in the Given phase:
/// - `.apiResponse()` — configure what the fake API returns
/// - `.credentials()` — set up login credentials
class AuthGivenBuilder extends GivenBuilder {
  AuthGivenBuilder(super.scenario);

  /// Configure the fake API response for this scenario.
  ApiResponseGivenBuilder apiResponse() =>
      ApiResponseGivenBuilder(scenario);

  /// Set up login credentials for this scenario.
  CredentialsGivenBuilder credentials() =>
      CredentialsGivenBuilder(scenario);
}
