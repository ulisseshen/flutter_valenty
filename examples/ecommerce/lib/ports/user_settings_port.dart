/// Port for user settings persistence (backed by SharedPreferences).
abstract class UserSettingsPort {
  Future<void> saveCurrency(String currencyCode);
  Future<String> getCurrency();
}
