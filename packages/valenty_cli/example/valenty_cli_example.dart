// ignore_for_file: avoid_print
/// Example: Using the Valenty CLI for Flutter component testing.
///
/// Install:
/// ```bash
/// dart pub global activate valenty_cli
/// ```
///
/// Initialize in your Flutter project:
/// ```bash
/// valenty init
/// ```
///
/// Scaffold a feature:
/// ```bash
/// valenty scaffold feature order --models lib/models/order.dart
/// ```
///
/// See the full documentation at https://github.com/valenty-dev/valenty
void main() {
  print('Valenty CLI commands:');
  print('  valenty init              — Setup project + AI skills');
  print('  valenty generate skills   — Regenerate AI skill files');
  print('  valenty scaffold feature  — Generate builder tree');
  print('  valenty list features     — List scaffolded features');
  print('  valenty validate          — Check builder correctness');
  print('  valenty test              — Run Valenty tests');
  print('  valenty doctor            — Check environment');
  print('  valenty update            — Self-update');
}
