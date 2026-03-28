import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valenty_test/valenty_test.dart';

import 'package:flutter_expense_tracker/screens/expense_list_screen.dart';

class ExpenseUiDriver extends UiDriver {
  ExpenseUiDriver(this.tester);

  final WidgetTester tester;

  Future<void> pumpApp() async {
    await tester.pumpWidget(
      const MaterialApp(home: ExpenseListScreen()),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapFab() async {
    await tester.tap(find.byKey(const Key('addExpenseFab')));
    await tester.pumpAndSettle();
  }

  Future<void> tapBudgetButton() async {
    await tester.tap(find.byKey(const Key('budgetButton')));
    await tester.pumpAndSettle();
  }

  Future<void> tapSubmit() async {
    await tester.tap(find.byKey(const Key('submitButton')));
    await tester.pumpAndSettle();
  }

  Future<void> enterDescription(String text) async {
    await tester.enterText(find.byKey(const Key('descriptionField')), text);
    await tester.pumpAndSettle();
  }

  Future<void> enterAmount(String text) async {
    await tester.enterText(find.byKey(const Key('amountField')), text);
    await tester.pumpAndSettle();
  }

  Future<void> selectCategory(String category) async {
    await tester.tap(find.byKey(const Key('categoryDropdown')));
    await tester.pump();
    await tester.tap(find.text(category).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapBack() async {
    final backButton = find.byType(BackButton);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
    } else {
      // Use navigator pop
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
    }
    await tester.pumpAndSettle();
  }

  void verifyText(String text) {
    expect(find.text(text), findsOneWidget);
  }

  void verifyNoText(String text) {
    expect(find.text(text), findsNothing);
  }

  void verifyListItemCount(int count) {
    expect(find.byType(ListTile), findsNWidgets(count));
  }

  void verifyTextExists(String text) {
    expect(find.text(text), findsWidgets);
  }

  void verifyValidationError(String text) {
    expect(find.text(text), findsOneWidget);
  }
}
