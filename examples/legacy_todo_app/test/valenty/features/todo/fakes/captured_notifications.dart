/// Captures notifications sent via NotificationHelper for test assertions.
///
/// Instead of actually sending push notifications, the test environment
/// redirects NotificationHelper.send() to this list.
class CapturedNotifications {
  final List<String> messages = [];

  void capture(String message) {
    messages.add(message);
  }

  bool get wasSent => messages.isNotEmpty;

  bool containsMessage(String substring) {
    return messages.any((msg) => msg.contains(substring));
  }

  void clear() {
    messages.clear();
  }
}
