import 'package:test/test.dart';
import 'package:valenty_test/src/core/phantom_types.dart';
import 'package:valenty_test/src/core/scenario_builder.dart';
import 'package:valenty_test/src/builders/feature_scenario.dart';
import 'package:valenty_test/src/builders/given_builder.dart';

class _SimpleGivenBuilder extends GivenBuilder {
  _SimpleGivenBuilder(super.scenario);

  bool domainMethodCalled = false;

  _SimpleGivenBuilder domainMethod() {
    domainMethodCalled = true;
    return this;
  }
}

class _SimpleScenario extends FeatureScenario<_SimpleGivenBuilder> {
  _SimpleScenario(super.description);

  @override
  _SimpleGivenBuilder createGivenBuilder(ScenarioBuilder<NeedsWhen> scenario) {
    return _SimpleGivenBuilder(scenario);
  }
}

void main() {
  group('FeatureScenario', () {
    test('given returns the feature-specific GivenBuilder', () {
      final scenario = _SimpleScenario('test');
      final given = scenario.given;
      expect(given, isA<_SimpleGivenBuilder>());
    });

    test('GivenBuilder has domain methods available', () {
      final scenario = _SimpleScenario('test');
      final given = scenario.given;
      given.domainMethod();
      expect(given.domainMethodCalled, isTrue);
    });

    test('GivenBuilder scenario is in NeedsWhen state', () {
      final scenario = _SimpleScenario('test');
      final given = scenario.given;
      expect(given.scenario, isA<ScenarioBuilder<NeedsWhen>>());
    });
  });
}
