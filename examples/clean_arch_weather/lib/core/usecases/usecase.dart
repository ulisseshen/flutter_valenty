/// Base class for all use cases in the application.
///
/// Each use case encapsulates a single piece of business logic.
/// [Type] is the return type, [Params] is the input parameter type.
///
/// Use [NoParams] when the use case takes no input.
abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

/// Marker class for use cases that take no parameters.
class NoParams {
  const NoParams();
}
