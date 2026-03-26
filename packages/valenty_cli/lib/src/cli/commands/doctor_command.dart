import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import '../../config/valenty_config.dart';

class DoctorCommand extends Command<void> {
  DoctorCommand({required Logger logger}) : _logger = logger;

  final Logger _logger;

  @override
  String get name => 'doctor';

  @override
  String get description => 'Check the project setup and environment.';

  @override
  Future<void> run() async {
    _logger.info('Valenty Doctor');
    _logger.info('=' * 40);
    _logger.info('');

    await _checkDartSdk();
    await _checkFlutterSdk();
    _checkPubspec();
    _checkValentyConfig();

    _logger.info('');
  }

  Future<void> _checkDartSdk() async {
    try {
      final result = await Process.run('dart', ['--version']);
      final output = (result.stderr as String).isNotEmpty
          ? result.stderr as String
          : result.stdout as String;
      final version = output.trim();
      _logger.info('${lightGreen.wrap('✓')} Dart SDK: $version');
    } on ProcessException {
      _logger.info('${red.wrap('✗')} Dart SDK: Not found');
    }
  }

  Future<void> _checkFlutterSdk() async {
    try {
      final result = await Process.run('flutter', ['--version']);
      final output = (result.stdout as String).split('\n').first.trim();
      _logger.info('${lightGreen.wrap('✓')} Flutter SDK: $output');
    } on ProcessException {
      _logger.info(
        '${yellow.wrap('○')} Flutter SDK: Not found (optional)',
      );
    }
  }

  void _checkPubspec() {
    final pubspecFile = File(
      '${Directory.current.path}/pubspec.yaml',
    );
    if (pubspecFile.existsSync()) {
      _logger.info('${lightGreen.wrap('✓')} pubspec.yaml: Found');
    } else {
      _logger.info('${red.wrap('✗')} pubspec.yaml: Not found');
    }
  }

  void _checkValentyConfig() {
    final config = ValentyConfig();
    if (config.exists()) {
      _logger.info(
        '${lightGreen.wrap('✓')} ${ValentyConfig.fileName}: Found',
      );
    } else {
      _logger.info(
        '${yellow.wrap('○')} ${ValentyConfig.fileName}: '
        'Not found (run "valenty init")',
      );
    }
  }
}
