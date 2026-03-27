class Budget {
  final String category;
  final double limit;
  final double spent;

  const Budget({
    required this.category,
    required this.limit,
    required this.spent,
  });

  double get remaining => limit - spent;
  bool get isOverBudget => spent > limit;
  double get progress => limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
}
