import 'package:test/test.dart';
import 'package:valenty_test/src/core/phantom_types.dart';
import 'package:valenty_test/src/core/scenario_builder.dart';
import 'package:valenty_test/src/core/step_record.dart';
import 'package:valenty_test/src/core/test_context.dart';
import 'package:valenty_test/src/builders/assertion_builder.dart';

class _TestAssertionBuilder extends AssertionBuilder {
  _TestAssertionBuilder(super.scenario);

  _TestAssertionBuilder hasValue(String expected) {
    addAssertionStep((ctx) {
      final actual = ctx.get<String>('value');
      expect(actual, equals(expected));
    }, description: 'has value $expected',);
    return this;
  }
}

void main() {
  group('AssertionBuilder', () {
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

    test('hasX methods return same builder for chaining', () {
      final builder = _TestAssertionBuilder(readyScenario);
      final result = builder.hasValue('test');
      expect(identical(result, builder), isTrue);
    });

    test('addAssertionStep registers step in scenario', () {
      final builder = _TestAssertionBuilder(readyScenario);
      builder.hasValue('test');

      final current = builder.currentScenario;
      expect(current.steps.length, readyScenario.steps.length + 1);
    });

    test('multiple hasX calls register multiple steps', () {
      final builder = _TestAssertionBuilder(readyScenario);
      builder.hasValue('a').hasValue('b');

      final current = builder.currentScenario;
      expect(current.steps.length, readyScenario.steps.length + 2);
    });

    test('registered assertion executes correctly', () {
      final builder = _TestAssertionBuilder(readyScenario);
      builder.hasValue('hello');

      final current = builder.currentScenario;
      final lastStep = current.steps.last;

      final ctx = TestContext();
      ctx.set('value', 'hello');
      // Should not throw
      lastStep.action(ctx);
    });
  });
}
