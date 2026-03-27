import '../ports/user_settings_port.dart';

/// Adapter that implements [UserSettingsPort] using SharedPreferences.
///
/// In a real Flutter project, this class would depend on the
/// `shared_preferences` package. Since this is a pure Dart example (no
/// Flutter SDK), we provide an in-memory implementation that demonstrates
/// the pattern.
///
/// ## Real Flutter implementation sketch
///
/// ```dart
/// import 'package:shared_preferences/shared_preferences.dart';
///
/// class PrefsUserSettings implements UserSettingsPort {
///   static const _currencyKey = 'user_currency';
///   static const _defaultCurrency = 'USD';
///
///   final SharedPreferences _prefs;
///
///   PrefsUserSettings(this._prefs);
///
///   /// Factory that awaits SharedPreferences initialization.
///   static Future<PrefsUserSettings> create() async {
///     final prefs = await SharedPreferences.getInstance();
///     return PrefsUserSettings(prefs);
///   }
///
///   @override
///   Future<void> saveCurrency(String currencyCode) async {
///     await _prefs.setString(_currencyKey, currencyCode);
///   }
///
///   @override
///   Future<String> getCurrency() async {
///     return _prefs.getString(_currencyKey) ?? _defaultCurrency;
///   }
/// }
/// ```
class PrefsUserSettings implements UserSettingsPort {
  PrefsUserSettings({String defaultCurrency = 'USD'})
      : _currency = defaultCurrency;

  /// In-memory store simulating SharedPreferences key-value storage.
  String _currency;

  @override
  Future<void> saveCurrency(String currencyCode) async {
    // In real implementation: _prefs.setString(_currencyKey, currencyCode)
    _currency = currencyCode;
  }

  @override
  Future<String> getCurrency() async {
    // In real implementation: _prefs.getString(_currencyKey) ?? _defaultCurrency
    return _currency;
  }
}
