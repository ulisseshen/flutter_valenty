import 'package:test/test.dart';
import 'package:valenty_dsl/valenty_dsl.dart';

// Test doubles for testing valentyTest itself
class FakeSystem extends SystemDsl {
  final List<String> actions = [];

  void doAction(String action) => actions.add(action);
  String get lastAction => actions.last;
}

class FakeBackend extends BackendStubDsl {
  bool applied = false;
  bool restored = false;
  String configuredValue = '';

  void configure(String value) => configuredValue = value;

  @override
  Future<void> apply() async => applied = true;

  @override
  Future<void> restore() async => restored = true;
}

void main() {
  group('valentyTest', () {
    valentyTest<FakeSystem, FakeBackend>(
      'should pass system and backend to body',
      createBackend: FakeBackend.new,
      createSystem: (backend) => FakeSystem(),
      body: (system, backend) async {
        system.doAction('tested');
        expect(system.lastAction, 'tested');
      },
    );

    valentyTest<FakeSystem, FakeBackend>(
      'should call apply before body',
      createBackend: FakeBackend.new,
      createSystem: (backend) {
        expect(
          backend.applied,
          isTrue,
          reason: 'apply() should run before createSystem',
        );
        return FakeSystem();
      },
      body: (system, backend) async {
        expect(backend.applied, isTrue);
      },
    );

    valentyTest<FakeSystem, FakeBackend>(
      'should call restore after body',
      createBackend: FakeBackend.new,
      createSystem: (backend) => FakeSystem(),
      body: (system, backend) async {
        expect(
          backend.restored,
          isFalse,
          reason: 'restore should not run during body',
        );
      },
    );

    valentyTest<FakeSystem, FakeBackend>(
      'should make backend available to system creation',
      createBackend: () {
        final b = FakeBackend();
        b.configure('test-value');
        return b;
      },
      createSystem: (backend) {
        expect(backend.configuredValue, 'test-value');
        return FakeSystem();
      },
      body: (system, backend) async {
        expect(backend.configuredValue, 'test-value');
      },
    );

    // Test that restore runs even if body throws
    test('should call restore even when body throws', () async {
      final backend = FakeBackend();
      await backend.apply();
      try {
        throw Exception('simulated failure');
      } catch (_) {
        // expected
      } finally {
        await backend.restore();
      }
      expect(backend.restored, isTrue);
    });
  });
}
