import 'package:legacy_todo_app_example/services/http_client.dart';
import 'package:legacy_todo_app_example/services/notification_helper.dart';
import 'package:legacy_todo_app_example/services/storage_service.dart';
import 'package:legacy_todo_app_example/services/todo_service.dart';

import '../fakes/captured_notifications.dart';
import '../fakes/fake_http_client.dart';

/// Test environment for the legacy Todo app.
///
/// Handles setup and teardown of singleton overrides using the
/// @visibleForTesting factory pattern. This is the key enabler
/// for testing legacy code without refactoring to clean architecture.
///
/// Usage:
/// ```dart
/// late TodoTestEnvironment env;
///
/// setUp(() {
///   env = TodoTestEnvironment()..apply();
/// });
///
/// tearDown(() {
///   env.restore();
/// });
/// ```
class TodoTestEnvironment {
  final FakeHttpClient fakeHttp;
  final CapturedNotifications capturedNotifications;

  TodoTestEnvironment()
      : fakeHttp = FakeHttpClient(),
        capturedNotifications = CapturedNotifications();

  /// Override singleton factories with test fakes.
  void apply() {
    // Override TodoService's HTTP client factory
    TodoService.httpClientFactory = () => fakeHttp;

    // Keep using the real StorageService singleton (it's in-memory anyway)
    TodoService.storageFactory = () => StorageService.instance;

    // Capture notifications instead of printing them
    NotificationHelper.sendFunction =
        (msg) => capturedNotifications.capture(msg);

    // Clear any leftover cache from previous tests
    StorageService.instance.clearForTesting();
  }

  /// Restore original factories — prevent test pollution.
  void restore() {
    TodoService.httpClientFactory = () => RealHttpClient();
    TodoService.storageFactory = () => StorageService.instance;
    NotificationHelper.resetForTesting();
    StorageService.instance.clearForTesting();
  }
}
