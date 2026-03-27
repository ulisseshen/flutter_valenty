/// Failure types used at the domain level instead of exceptions.
///
/// Domain code never catches exceptions directly — it uses [Failure]
/// subtypes to represent known error states in a type-safe way.
sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Remote API returned an error response.
final class ServerFailure extends Failure {
  const ServerFailure(super.message, {required this.statusCode});

  final int statusCode;
}

/// Local cache read/write failed.
final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Device has no network connectivity.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No network connection']);
}
