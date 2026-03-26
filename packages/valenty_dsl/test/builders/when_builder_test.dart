import 'package:test/test.dart';
import 'package:valenty_dsl/src/core/phantom_types.dart';
import 'package:valenty_dsl/src/core/scenario_builder.dart';
import 'package:valenty_dsl/src/core/step_record.dart';
import 'package:valenty_dsl/src/builders/when_builder.dart';

class _TestWhenBuilder extends WhenBuilder {
  _TestWhenBuilder(super.scenario);

  bool placeOrderCalled = false;

  _TestWhenBuilder placeOrder() {
    placeOrderCalled = true;
    return this;
  }
}

void main() {
  group('WhenBuilder', () {
    test('stores scenario in NeedsThen state', () {
      final scenario = ScenarioBuilder.create('test')
          .addStep<NeedsWhen>(
            StepRecord(phase: StepPhase.given, action: (_) {}),
          )
          .addStep<NeedsThen>(
            StepRecord(phase: StepPhase.when, action: (_) {}),
          );
      final builder = _TestWhenBuilder(scenario);
      expect(builder.scenario, isA<ScenarioBuilder<NeedsThen>>());
    });

    test('subclass can define use case methods', () {
      final scenario = ScenarioBuilder.create('test')
          .addStep<NeedsWhen>(
            StepRecord(phase: StepPhase.given, action: (_) {}),
          )
          .addStep<NeedsThen>(
            StepRecord(phase: StepPhase.when, action: (_) {}),
          );
      final builder = _TestWhenBuilder(scenario);
      builder.placeOrder();
      expect(builder.placeOrderCalled, isTrue);
    });
  });
}
