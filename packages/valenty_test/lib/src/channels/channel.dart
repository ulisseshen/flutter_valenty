/// Base interface for all test channels.
/// Channels represent the entry point through which users interact with the
/// system.
abstract interface class Channel {
  /// Human-readable name of this channel.
  String get name;
}
