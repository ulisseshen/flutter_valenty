import 'package:test/test.dart';
import 'package:valenty_test/src/core/phantom_types.dart';
import 'package:valenty_test/src/core/scenario_builder.dart';
import 'package:valenty_test/src/core/step_record.dart';
import 'package:valenty_test/src/runner/scenario_runner.dart';

void main() {
  group('ScenarioRunner', () {
    test('execute runs all steps in order', () async {
      final executionOrder = <int>[];

      final scenario = ScenarioBuilder.create('execution order test')
          .addStep<NeedsWhen>(
            StepRecord(
              phase: StepPhase.given,
              action: (_) => executionOrder.add(1),
            ),
          )
          .addStep<NeedsThen>(
            StepRecord(
              phase: StepPhase.when,
              action: (_) => executionOrder.add(2),
            ),
          )
          .addStep<ReadyToRun>(
            StepRecord(
              phase: StepPhase.then,
              action: (_) => executionOrder.add(3),
            ),
          );

      await ScenarioRunner.execute(scenario);
      expect(executionOrder, [1, 2, 3]);
    });

    test('execute handles async steps', () async {
      final executionOrder = <int>[];

      final scenario = ScenarioBuilder.create('async test')
          .addStep<NeedsWhen>(
            StepRecord(
              phase: StepPhase.given,
              action: (_) async {
                await Future<void>.delayed(Duration(milliseconds: 1));
                executionOrder.add(1);
              },
            ),
          )
          .addStep<NeedsThen>(
            StepRecord(
              phase: StepPhase.when,
              action: (_) async {
                await Future<void>.delayed(Duration(milliseconds: 1));
                executionOrder.add(2);
              },
            ),
          )
          .addStep<ReadyToRun>(
            StepRecord(
              phase: StepPhase.then,
              action: (_) => executionOrder.add(3),
            ),
          );

      await ScenarioRunner.execute(scenario);
      expect(executionOrder, [1, 2, 3]);
    });

    test('execute passes shared context between steps', () async {
      final scenario = ScenarioBuilder.create('context test')
          .addStep<NeedsWhen>(
            StepRecord(
              phase: StepPhase.given,
              action: (ctx) => ctx.set('value', 42),
            ),
          )
          .addStep<NeedsThen>(
            StepRecord(
              phase: StepPhase.when,
              action: (ctx) {
                final v = ctx.get<int>('value');
                ctx.set('doubled', v * 2);
              },
            ),
          )
          .addStep<ReadyToRun>(
            StepRecord(
              phase: StepPhase.then,
              action: (ctx) {
                expect(ctx.get<int>('doubled'), 84);
              },
            ),
          );

      await ScenarioRunner.execute(scenario);
    });
  });
}
