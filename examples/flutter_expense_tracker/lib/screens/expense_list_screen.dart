import 'package:flutter/material.dart';

import '../services/expense_service.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';
import 'budget_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  late Future<List<Expense>> _expensesFuture;

  @override
  void initState() {
    super.initState();
    _expensesFuture = ExpenseService.instance.fetchExpenses();
  }

  void _refresh() {
    setState(() {
      _expensesFuture = ExpenseService.instance.fetchExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            key: const Key('budgetButton'),
            icon: const Icon(Icons.pie_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BudgetScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Expense>>(
        future: _expensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data ?? [];

          if (expenses.isEmpty) {
            return const Center(child: Text('No expenses yet'));
          }

          final total = expenses.fold<double>(
            0,
            (sum, e) => sum + e.amount,
          );

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return ListTile(
                      title: Text(expense.description),
                      subtitle: Text(expense.category),
                      trailing: Text(
                        '\$${expense.amount.toStringAsFixed(2)}',
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  key: const Key('total'),
                  'Total: \$${total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addExpenseFab'),
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          if (result == true) {
            _refresh();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
