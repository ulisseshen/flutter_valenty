import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();

  @visibleForTesting
  static void Function(String message)? showOverride;

  static void show(String message) {
    if (showOverride != null) {
      showOverride!(message);
      return;
    }
    // Default: no-op (in production, integrate with a real notification system)
  }

  @visibleForTesting
  static void resetForTesting() {
    showOverride = null;
  }
}
