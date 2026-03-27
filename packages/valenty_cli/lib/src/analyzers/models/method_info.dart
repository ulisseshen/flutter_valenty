/// Information about a single method extracted from a builder class.
class MethodInfo {
  const MethodInfo({
    required this.name,
    required this.returnType,
    this.parameters = const [],
  });

  /// The method name (e.g. `withUnitPrice`, `hasBasePrice`, `placeOrder`).
  final String name;

  /// The declared return type of the method.
  final String returnType;

  /// Parameter signatures (e.g. `['double price', 'int quantity']`).
  final List<String> parameters;

  Map<String, dynamic> toJson() => {
        'name': name,
        'returnType': returnType,
        if (parameters.isNotEmpty) 'parameters': parameters,
      };
}
