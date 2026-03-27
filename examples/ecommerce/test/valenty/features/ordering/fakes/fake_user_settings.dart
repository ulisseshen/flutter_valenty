import 'package:ecommerce_example/ports/user_settings_port.dart';

/// In-memory fake for UserSettingsPort (replaces SharedPreferences).
class FakeUserSettings implements UserSettingsPort {
  final Map<String, String> _store = {};

  @override
  Future<void> saveCurrency(String currencyCode) async {
    _store['currency'] = currencyCode;
  }

  @override
  Future<String> getCurrency() async {
    return _store['currency'] ?? 'USD';
  }
}
