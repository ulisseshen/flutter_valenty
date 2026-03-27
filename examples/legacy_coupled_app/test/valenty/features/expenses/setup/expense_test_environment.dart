import 'package:legacy_coupled_app_example/services/auth_manager.dart';
import 'package:legacy_coupled_app_example/services/expense_screen_controller.dart';
import 'package:legacy_coupled_app_example/services/http_client.dart';
import 'package:legacy_coupled_app_example/services/local_storage.dart';
import 'package:legacy_coupled_app_example/services/notification_service.dart';

import '../fakes/fake_http_client.dart';

/// Test environment for the legacy coupled expense app.
///
/// Handles setup and teardown of ALL singleton overrides:
/// - ExpenseScreenController factories (HTTP + clock)
/// - AuthManager singleton state
/// - LocalStorage singleton state
/// - NotificationService static function
///
/// This is the key enabler for testing legacy code without refactoring
/// to clean architecture.
class ExpenseTestEnvironment {
  final FakeHttpClient fakeHttp;
  final List<String> capturedWarnings;

  ExpenseTestEnvironment()
      : fakeHttp = FakeHttpClient(),
        capturedWarnings = [];

  /// Override singleton factories with test fakes.
  void apply() {
    ExpenseScreenController.httpClientFactory = () => fakeHttp;
    ExpenseScreenController.clockFactory = () => DateTime(2025, 6, 15, 10, 30);
    AuthManager.instance.resetForTesting();
    LocalStorage.instance.clearForTesting();
    NotificationService.showWarningFn = (msg) => capturedWarnings.add(msg);
  }

  /// Restore original factories — prevent test pollution.
  void restore() {
    ExpenseScreenController.httpClientFactory = () => RealHttpClient();
    ExpenseScreenController.clockFactory = () => DateTime.now();
    AuthManager.instance.resetForTesting();
    LocalStorage.instance.clearForTesting();
    NotificationService.resetForTesting();
  }
}
