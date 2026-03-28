import 'package:test/test.dart';
import 'package:valenty_test/src/core/phantom_types.dart';
import 'package:valenty_test/src/core/scenario_builder.dart';
import 'package:valenty_test/src/core/step_record.dart';
import 'package:valenty_test/src/core/test_context.dart';
import 'package:valenty_test/src/builders/domain_object_builder.dart';

/// Concrete test implementation of DomainObjectBuilder.
class _TestDomainBuilder extends DomainObjectBuilder<NeedsWhen> {
  _TestDomainBuilder(ScenarioBuilder<NeedsWhen> scenario)
      : super(scenario, StepPhase.given);

  String _value = 'default';

  _TestDomainBuilder withValue(String value) {
    _value = value;
    return this;
  }

  @override
  void applyToContext(TestContext ctx) {
    ctx.set('test_value', _value);
  }
}

void main() {
  group('DomainObjectBuilder', () {
    late ScenarioBuilder<NeedsWhen> scenario;

    setUp(() {
      scenario = ScenarioBuilder.create('test').addStep<NeedsWhen>(
        StepRecord(phase: StepPhase.given, action: (_) {}),
      );
    });

    test('withX methods return same builder for chaining', () {
      final builder = _TestDomainBuilder(scenario);
      final result = builder.withValue('hello');
      expect(identical(result, builder), isTrue);
    });

    test('finalizeStep registers a step and returns scenario', () {
      final builder = _TestDomainBuilder(scenario);
      builder.withValue('hello');

      final finalized = builder.finalizeStep();
      expect(finalized, isA<ScenarioBuilder<NeedsWhen>>());
      // Original scenario had 1 step; finalized has 2
      expect(finalized.steps.length, scenario.steps.length + 1);
    });

    test('applyToContext stores values in context when step executes', () {
      final builder = _TestDomainBuilder(scenario);
      builder.withValue('hello');

      final finalized = builder.finalizeStep();
      final lastStep = finalized.steps.last;

      // Execute the step action
      final ctx = TestContext();
      lastStep.action(ctx);
      expect(ctx.get<String>('test_value'), 'hello');
    });

    test('default values are applied when no withX is called', () {
      final builder = _TestDomainBuilder(scenario);
      final finalized = builder.finalizeStep();
      final lastStep = finalized.steps.last;

      final ctx = TestContext();
      lastStep.action(ctx);
      expect(ctx.get<String>('test_value'), 'default');
    });
  });
}
