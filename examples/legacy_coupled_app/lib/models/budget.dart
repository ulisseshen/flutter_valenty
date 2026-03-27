/// Budget model — also with fromJson/toJson in domain (BAD but real).
class Budget {
  final String category;
  final double limit;
  final double spent;

  const Budget({
    required this.category,
    required this.limit,
    required this.spent,
  });

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        category: json['category'] as String,
        limit: (json['limit'] as num).toDouble(),
        spent: (json['spent'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'category': category,
        'limit': limit,
        'spent': spent,
      };
}
