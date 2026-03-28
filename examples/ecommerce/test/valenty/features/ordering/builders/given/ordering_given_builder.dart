import 'package:valenty_test/valenty_test.dart';

import 'api_config_given_builder.dart';
import 'catalog_given_builder.dart';
import 'currency_given_builder.dart';

/// GivenBuilder for the Ordering feature.
///
/// Provides domain objects available in the Given phase:
/// - `.catalog()` — set up products in the fake catalog
/// - `.currency()` — set preferred currency in fake settings
/// - `.apiConfig()` — configure fake order API behavior
class OrderingGivenBuilder extends GivenBuilder {
  OrderingGivenBuilder(super.scenario);

  /// Set up a product in the catalog.
  CatalogGivenBuilder catalog() => CatalogGivenBuilder(scenario);

  /// Set preferred currency.
  CurrencyGivenBuilder currency() => CurrencyGivenBuilder(scenario);

  /// Configure API behavior (success/failure).
  ApiConfigGivenBuilder apiConfig() => ApiConfigGivenBuilder(scenario);
}
