import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';
import 'package:valenty_cli/valenty_cli.dart';

void main() {
  group('CliRunner', () {
    late CliRunner runner;
    late Logger logger;

    setUp(() {
      logger = Logger();
      runner = CliRunner(logger: logger);
    });

    test('can be instantiated', () {
      expect(runner, isNotNull);
    });

    test('has correct executable name', () {
      expect(runner.executableName, equals('valenty'));
    });

    test('has correct description', () {
      expect(
        runner.description,
        equals('Install AI skills for compile-time safe acceptance testing.'),
      );
    });

    test('registers all commands', () {
      final commandNames = runner.commands.keys.toList()..sort();
      expect(
        commandNames,
        equals([
          'context',
          'doctor',
          'generate',
          'help',
          'init',
          'list',
          'scaffold',
          'test',
          'update',
          'validate',
        ]),
      );
    });

    test('--help shows usage', () {
      expect(runner.usage, contains('valenty'));
      expect(runner.usage, contains('--version'));
      expect(runner.usage, contains('--help'));
    });

    test('--version prints version', () async {
      // Should not throw
      await runner.run(['--version']);
    });
  });
}
