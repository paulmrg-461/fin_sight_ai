/// Exceptions raised by infrastructure and caught at the data-layer boundary.
///
/// These types must never escape a repository: repositories translate them
/// into [Failure] values.
class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

/// A remote call failed (network, timeout, non-2xx response).
final class ServerException extends AppException {
  const ServerException(super.message, {super.code});
}

/// The local store failed to read or write.
final class CacheException extends AppException {
  const CacheException(super.message, {super.code});
}

/// Input failed a precondition check inside the data layer.
final class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}
