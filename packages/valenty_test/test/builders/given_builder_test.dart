import 'package:test/test.dart';
import 'package:valenty_test/src/core/phantom_types.dart';
import 'package:valenty_test/src/core/scenario_builder.dart';
import 'package:valenty_test/src/core/step_record.dart';
import 'package:valenty_test/src/builders/given_builder.dart';

class _TestGivenBuilder extends GivenBuilder {
  _TestGivenBuilder(super.scenario);

  bool productCalled = false;

  _TestGivenBuilder product() {
    productCalled = true;
    return this;
  }
}

void main() {
  group('GivenBuilder', () {
    test('stores scenario in NeedsWhen state', () {
      final scenario = ScenarioBuilder.create('test').addStep<NeedsWhen>(
        StepRecord(phase: StepPhase.given, action: (_) {}),
      );
      final builder = _TestGivenBuilder(scenario);
      expect(builder.scenario, isA<ScenarioBuilder<NeedsWhen>>());
    });

    test('subclass can define domain methods', () {
      final scenario = ScenarioBuilder.create('test').addStep<NeedsWhen>(
        StepRecord(phase: StepPhase.given, action: (_) {}),
      );
      final builder = _TestGivenBuilder(scenario);
      builder.product();
      expect(builder.productCalled, isTrue);
    });
  });
}
