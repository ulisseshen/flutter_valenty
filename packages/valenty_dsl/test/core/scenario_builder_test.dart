import 'package:test/test.dart';
import 'package:valenty_dsl/src/core/phantom_types.dart';
import 'package:valenty_dsl/src/core/scenario_builder.dart';
import 'package:valenty_dsl/src/core/step_record.dart';

void main() {
  group('ScenarioBuilder', () {
    test('create returns ScenarioBuilder<NeedsGiven>', () {
      final builder = ScenarioBuilder.create('test scenario');
      expect(builder, isA<ScenarioBuilder<NeedsGiven>>());
      expect(builder.description, 'test scenario');
      expect(builder.steps, isEmpty);
    });

    test('addStep transitions phantom type', () {
      final builder = ScenarioBuilder.create('test');
      final next = builder.addStep<NeedsWhen>(
        StepRecord(phase: StepPhase.given, action: (_) {}),
      );

      expect(next, isA<ScenarioBuilder<NeedsWhen>>());
      expect(next.steps.length, 1);
      expect(next.steps.first.phase, StepPhase.given);
    });

    test('appendStep keeps same phantom type', () {
      final builder = ScenarioBuilder.create('test');
      final inWhen = builder.addStep<NeedsWhen>(
        StepRecord(phase: StepPhase.given, action: (_) {}),
      );
      final withExtra = inWhen.appendStep(
        StepRecord(phase: StepPhase.and, action: (_) {}),
      );

      expect(withExtra, isA<ScenarioBuilder<NeedsWhen>>());
      expect(withExtra.steps.length, 2);
    });

    test('context is shared across state transitions', () {
      final builder = ScenarioBuilder.create('test');
      final next = builder.addStep<NeedsWhen>(
        StepRecord(phase: StepPhase.given, action: (_) {}),
      );

      builder.context.set('shared', 42);
      expect(next.context.get<int>('shared'), 42);
    });

    test('steps list is immutable', () {
      final builder = ScenarioBuilder.create('test');
      expect(
        () => builder.steps.add(
          StepRecord(phase: StepPhase.given, action: (_) {}),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('full chain NeedsGiven -> NeedsWhen -> NeedsThen -> ReadyToRun', () {
      final s0 = ScenarioBuilder.create('test');
      expect(s0, isA<ScenarioBuilder<NeedsGiven>>());

      final s1 = s0.addStep<NeedsWhen>(
        StepRecord(phase: StepPhase.given, action: (_) {}),
      );
      expect(s1, isA<ScenarioBuilder<NeedsWhen>>());

      final s2 = s1.addStep<NeedsThen>(
        StepRecord(phase: StepPhase.when, action: (_) {}),
      );
      expect(s2, isA<ScenarioBuilder<NeedsThen>>());

      final s3 = s2.addStep<ReadyToRun>(
        StepRecord(phase: StepPhase.then, action: (_) {}),
      );
      expect(s3, isA<ScenarioBuilder<ReadyToRun>>());
      expect(s3.steps.length, 3);
    });
  });
}
