import 'package:flutter/material.dart';

import '../models/budget.dart';
import '../services/expense_service.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Summary'),
      ),
      body: FutureBuilder<List<Budget>>(
        future: ExpenseService.instance.getBudgets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final budgets = snapshot.data ?? [];

          if (budgets.isEmpty) {
            return const Center(child: Text('No budgets configured'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.category,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${budget.spent.toStringAsFixed(2)} / \$${budget.limit.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: budget.progress,
                        backgroundColor: Colors.grey[300],
                        color: budget.isOverBudget ? Colors.red : Colors.green,
                      ),
                      if (budget.isOverBudget) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Over budget!',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
