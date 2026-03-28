/// Base class for UI drivers that interact with the application under test.
///
/// In Flutter projects, extend this with a driver that wraps [WidgetTester]:
///
/// ```dart
/// class OrderUiDriver extends UiDriver {
///   OrderUiDriver(this.tester);
///   final WidgetTester tester;
///
///   Future<void> pumpApp() async {
///     await tester.pumpWidget(const MaterialApp(home: OrderScreen()));
///     await tester.pumpAndSettle();
///   }
///
///   Future<void> tapProduct(String sku) async {
///     await tester.tap(find.text(sku));
///     await tester.pumpAndSettle();
///   }
///
///   Future<void> enterQuantity(int qty) async {
///     await tester.enterText(find.byKey(const Key('quantity')), '$qty');
///     await tester.pumpAndSettle();
///   }
///
///   Future<void> verifyText(String text) async {
///     expect(find.text(text), findsOneWidget);
///   }
/// }
/// ```
///
/// For pure Dart tests (no Flutter), a driver can wrap service calls instead
/// of widget interactions.
abstract class UiDriver {
  const UiDriver();
}
