// =============================================================================
// SCAFFOLD FEATURE ACCEPTANCE TESTS
// =============================================================================
//
// QA Scenarios (plain English from QA team):
//
//   1. "Given a Dart project with a Product model (name: String, unitPrice: double),
//       when scaffold is run for feature 'order' with the Product model,
//       then it should succeed
//       and generated files should have a scenario file,
//       and should have a given builder,
//       and should have a domain object builder for Product"
//
//   2. "Given a Dart project with two models (Product and Order),
//       when scaffold is run for feature 'order' with both models,
//       then generated files should have domain object builders for both models"
//
//   3. "Given a Dart project with no model files provided,
//       when scaffold is run for feature 'order' with empty model paths,
//       then it should fail"
//
// AI translated these scenarios into compile-time safe typed DSL below.
// No strings. No runtime failures. IDE guides every step.
// =============================================================================

import 'package:test/test.dart';

import '../scaffold_scenario.dart';

void main() {
  group('Scaffold Feature', () {

    // ─── QA Scenario 1 ─────────────────────────────────────────────────
    // "Given a Dart project with a Product model (name: String, unitPrice: double),
    //  when scaffold is run for feature 'order' with the Product model,
    //  then it should succeed
    //  and generated files should have a scenario file,
    //  and should have a given builder,
    //  and should have a domain object builder for Product"
    //
    ScaffoldScenario(
      'should generate builder tree for a single model',
    )
        .given
        .project()
        .withName('my_app')
        .and
        .modelFile()
        .withClassName('Product')
        .withFields({'name': 'String', 'unitPrice': 'double'})
        .atPath('lib/models/product.dart')
        .when
        .runScaffold()
        .withFeatureName('order')
        .withModelPaths(['lib/models/product.dart'])
        .then
        .shouldSucceed()
        .and
        .generatedFiles()
        .hasScenarioFile()
        .hasGivenBuilder()
        .hasDomainObjectBuilder('Product')
        .hasWhenBuilder()
        .hasThenBuilder()
        .hasAssertionBuilder('Product')
        .run();

    // ─── QA Scenario 2 ─────────────────────────────────────────────────
    // "Given a Dart project with two models (Product and Order),
    //  when scaffold is run for feature 'order' with both models,
    //  then generated files should have domain object builders for both models"
    //
    ScaffoldScenario(
      'should generate domain object builders for multiple models',
    )
        .given
        .project()
        .withName('my_app')
        .and
        .modelFile()
        .withClassName('Product')
        .withFields({'name': 'String', 'unitPrice': 'double'})
        .atPath('lib/models/product.dart')
        .and
        .modelFile()
        .withClassName('OrderItem')
        .withFields({'quantity': 'int', 'productId': 'String'})
        .atPath('lib/models/order_item.dart')
        .when
        .runScaffold()
        .withFeatureName('order')
        .withModelPaths([
          'lib/models/product.dart',
          'lib/models/order_item.dart',
        ])
        .then
        .generatedFiles()
        .hasScenarioFile()
        .hasGivenBuilder()
        .hasDomainObjectBuilder('Product')
        .hasDomainObjectBuilder('OrderItem')
        .hasWhenBuilder()
        .hasThenBuilder()
        .hasAssertionBuilder('Product')
        .hasAssertionBuilder('OrderItem')
        .run();

    // ─── QA Scenario 3 ─────────────────────────────────────────────────
    // "Given a Dart project with no model files provided,
    //  when scaffold is run for feature 'order' with empty model paths,
    //  then it should fail"
    //
    ScaffoldScenario(
      'should fail when no model files are provided',
    )
        .given
        .project()
        .withName('my_app')
        .when
        .runScaffold()
        .withFeatureName('order')
        .withModelPaths([])
        .then
        .shouldFail()
        .run();
  });
}
