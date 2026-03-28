import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'commands/context_command.dart';
import 'commands/doctor_command.dart';
import 'commands/generate_command.dart';
import 'commands/init_command.dart';
import 'commands/list_command.dart';
import 'commands/scaffold_command.dart';
import 'commands/test_command.dart';
import 'commands/update_command.dart';
import 'commands/validate_command.dart';

/// The main command runner for the Valenty CLI.
///
/// Registers all available sub-commands (`init`, `generate`, `doctor`,
/// `update`, `scaffold`, `list`, `context`, `validate`, `test`) and handles
/// the top-level `--version` flag.
///
/// ```dart
/// final runner = CliRunner();
/// await runner.run(['init']);
/// ```
class CliRunner extends CommandRunner<void> {
  /// Creates a new [CliRunner] instance.
  ///
  /// An optional [logger] can be provided for output; if omitted a default
  /// [Logger] is used.
  CliRunner({Logger? logger})
      : _logger = logger ?? Logger(),
        super(
          'valenty',
          'Install AI skills for compile-time safe acceptance testing.',
        ) {
    addCommand(InitCommand(logger: _logger));
    addCommand(GenerateCommand(logger: _logger));
    addCommand(DoctorCommand(logger: _logger));
    addCommand(UpdateCommand(logger: _logger));
    addCommand(ScaffoldCommand(logger: _logger));
    addCommand(ListCommand(logger: _logger));
    addCommand(ContextCommand(logger: _logger));
    addCommand(ValidateCommand(logger: _logger));
    addCommand(TestCommand(logger: _logger));
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the current version.',
    );
  }

  final Logger _logger;

  /// Parses [args] and runs the matching sub-command.
  ///
  /// If the `--version` flag is present, prints the current version and
  /// returns without executing any sub-command.
  @override
  Future<void> run(Iterable<String> args) async {
    final topLevelResults = parse(args);
    if (topLevelResults['version'] == true) {
      _logger.info('valenty 0.1.0');
      return;
    }
    return super.run(args);
  }
}
