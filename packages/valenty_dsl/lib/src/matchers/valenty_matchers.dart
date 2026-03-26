import 'package:test/test.dart';

/// Matcher that checks a specific field of an object.
Matcher hasField<T>(
  String fieldName,
  Object? Function(T obj) getter,
  dynamic expected,
) {
  return predicate<T>(
    (obj) {
      final value = getter(obj);
      if (expected is Matcher) {
        return expected.matches(value, {});
      }
      return value == expected;
    },
    'has $fieldName equal to $expected',
  );
}

/// Matcher that checks multiple conditions.
Matcher satisfiesAll(List<Matcher> matchers) {
  return predicate(
    (obj) => matchers.every((m) => m.matches(obj, {})),
    'satisfies all ${matchers.length} conditions',
  );
}
