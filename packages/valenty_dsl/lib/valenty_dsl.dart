/// Compile-time safe typed fluent builder DSL for Dart/Flutter testing
/// with phantom types.
library;

// Core
export 'src/core/annotations.dart';
export 'src/core/phantom_types.dart';
export 'src/core/scenario_builder.dart';
export 'src/core/scenario_extensions.dart';
export 'src/core/step_record.dart';
export 'src/core/test_context.dart';
export 'src/core/test_environment.dart';

// Builders
export 'src/builders/and_given_builder.dart';
export 'src/builders/and_then_builder.dart';
export 'src/builders/assertion_builder.dart';
export 'src/builders/domain_object_builder.dart';
export 'src/builders/feature_scenario.dart';
export 'src/builders/given_builder.dart';
export 'src/builders/then_builder.dart';
export 'src/builders/when_builder.dart';

// Runner
export 'src/runner/scenario_runner.dart';

// Channels
export 'src/channels/channel.dart';
export 'src/channels/ui_channel.dart';
export 'src/channels/api_channel.dart';
export 'src/channels/cli_channel.dart';

// Drivers
export 'src/drivers/driver.dart';
export 'src/drivers/flutter_widget_driver.dart';
export 'src/drivers/http_driver.dart';

// Fixtures
export 'src/fixtures/fixture_base.dart';
export 'src/fixtures/creation_methods.dart';
export 'src/fixtures/test_data_builder.dart';

// Matchers
export 'src/matchers/valenty_matchers.dart';
export 'src/matchers/delta_assertion.dart';

// Helpers
export 'src/helpers/parameterized_test.dart';
export 'src/helpers/guard_assertion.dart';
