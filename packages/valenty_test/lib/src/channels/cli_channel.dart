import 'channel.dart';

/// Channel for CLI-based interactions.
abstract class CliChannel implements Channel {
  @override
  String get name => 'CLI';
}
