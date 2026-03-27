/// Exceptions thrown by data-layer implementations.
///
/// These are caught inside the repository and converted to [Failure] types
/// before reaching the domain layer.

/// Thrown by remote datasources when the API returns a non-2xx status.
class ServerException implements Exception {
  const ServerException(this.message, {required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() => 'ServerException($statusCode): $message';
}

/// Thrown by local datasources when a cache operation fails.
class CacheException implements Exception {
  const CacheException(this.message);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}
