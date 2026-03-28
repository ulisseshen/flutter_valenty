import 'channel.dart';

/// Channel for UI-based interactions (e.g., Flutter widgets, web UI).
abstract class UiChannel implements Channel {
  @override
  String get name => 'UI';
}
