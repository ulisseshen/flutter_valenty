/// Domain entity that WRONGLY imports data layer concerns.
/// In clean code, entities should have zero dependencies.
class Expense {
  final String id;
  final String description;
  final double amount;
  final String category;
  final String userId;
  final DateTime date;

  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.userId,
    required this.date,
  });

  // BAD: fromJson in domain entity (should be in a data model)
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  // BAD: toJson in domain entity
  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'category': category,
        'userId': userId,
        'date': date.toIso8601String(),
      };
}
