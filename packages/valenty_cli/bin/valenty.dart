import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:valenty_cli/valenty_cli.dart';

Future<void> main(List<String> args) async {
  try {
    await CliRunner().run(args);
  } on UsageException catch (e) {
    final logger = Logger();
    logger.err(e.message);
    logger.info(e.usage);
  }
}
