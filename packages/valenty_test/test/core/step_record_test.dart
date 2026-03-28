import 'package:test/test.dart';
import 'package:valenty_test/src/core/step_record.dart';
import 'package:valenty_test/src/core/test_context.dart';

void main() {
  group('StepRecord', () {
    test('stores phase and action', () {
      final record = StepRecord(
        phase: StepPhase.given,
        action: (ctx) => ctx.set('key', 'value'),
      );

      expect(record.phase, StepPhase.given);
      expect(record.description, isNull);

      final ctx = TestContext();
      record.action(ctx);
      expect(ctx.get<String>('key'), 'value');
    });

    test('stores optional description', () {
      final record = StepRecord(
        phase: StepPhase.then,
        action: (_) {},
        description: 'should have base price',
      );

      expect(record.description, 'should have base price');
    });

    test('all StepPhase values are accessible', () {
      expect(StepPhase.values, containsAll([
        StepPhase.given,
        StepPhase.when,
        StepPhase.then,
        StepPhase.and,
      ]),);
    });
  });
}
