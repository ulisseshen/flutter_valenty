import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

class UpdateCommand extends Command<void> {
  UpdateCommand({
    required Logger logger,
    PubUpdater? pubUpdater,
  })  : _logger = logger,
        _pubUpdater = pubUpdater ?? PubUpdater();

  final Logger _logger;
  final PubUpdater _pubUpdater;

  static const String _packageName = 'valenty_cli';
  static const String _currentVersion = '0.1.0';

  @override
  String get name => 'update';

  @override
  String get description => 'Check for updates to the Valenty CLI.';

  @override
  Future<void> run() async {
    final progress = _logger.progress('Checking for updates');

    try {
      final latestVersion = await _pubUpdater.getLatestVersion(
        _packageName,
      );

      if (latestVersion == _currentVersion) {
        progress.complete(
          'Valenty CLI is already up to date ($_currentVersion).',
        );
      } else {
        progress.complete(
          'Update available: $_currentVersion → $latestVersion',
        );
        _logger.info(
          'Run "dart pub global activate valenty_cli" to update.',
        );
      }
    } on Exception catch (e) {
      progress.fail('Failed to check for updates: $e');
    }
  }
}
