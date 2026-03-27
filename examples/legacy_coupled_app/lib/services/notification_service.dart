import 'package:meta/meta.dart';

/// NotificationService — static, no instance.
///
/// BAD: Static methods only, no way to inject fakes without @visibleForTesting.
class NotificationService {
  NotificationService._();

  @visibleForTesting
  static void Function(String message) showWarningFn = _defaultWarning;

  static void _defaultWarning(String message) {
    // ignore: avoid_print
    print('WARNING: $message');
  }

  static void showWarning(String message) => showWarningFn(message);

  @visibleForTesting
  static void resetForTesting() {
    showWarningFn = _defaultWarning;
  }
}
