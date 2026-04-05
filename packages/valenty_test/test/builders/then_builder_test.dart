import 'package:test/test.dart';
import 'package:valenty_test/src/core/phantom_types.dart';
import 'package:valenty_test/src/core/scenario_builder.dart';
import 'package:valenty_test/src/core/step_record.dart';
import 'package:valenty_test/src/core/test_context.dart';
import 'package:valenty_test/src/builders/then_builder.dart';

class _TestThenBuilder extends ThenBuilder {
  _TestThenBuilder(super.scenario);

  ScenarioBuilder<ReadyToRun> shouldSucceed() {
    return registerAssertion(
      (ctx) {
        expect(ctx.get<bool>('success'), isTrue);
      },
      description: 'should succeed',
    );
  }
}

void main() {
  group('ThenBuilder', () {
    late ScenarioBuilder<ReadyToRun> readyScenario;

    setUp(() {
      readyScenario = ScenarioBuilder.create('test')
          .addStep<NeedsWhen>(
            StepRecord(phase: StepPhase.given, action: (_) {}),
          )
          .addStep<NeedsThen>(
            StepRecord(phase: StepPhase.when, action: (_) {}),
          )
          .addStep<ReadyToRun>(
            StepRecord(phase: StepPhase.then, action: (_) {}),
          );
    });

    test('stores scenario in ReadyToRun state', () {
      final builder = _TestThenBuilder(readyScenario);
      expect(builder.scenario, isA<ScenarioBuilder<ReadyToRun>>());
    });

    test('registerAssertion adds step and returns ReadyToRun', () {
      final builder = _TestThenBuilder(readyScenario);
      final result = builder.shouldSucceed();

      expect(result, isA<ScenarioBuilder<ReadyToRun>>());
      expect(result.steps.length, readyScenario.steps.length + 1);
    });

    test('registered assertion executes correctly', () {
      final builder = _TestThenBuilder(readyScenario);
      final result = builder.shouldSucceed();

      final lastStep = result.steps.last;
      final ctx = TestContext();
      ctx.set('success', true);
      // Should not throw
      lastStep.action(ctx);
    });
  });
}
