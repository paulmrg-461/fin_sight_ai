/// Recoverable, user-facing errors returned by repositories and use cases.
///
/// A `Failure` replaces exceptions at layer boundaries: the data layer catches
/// infrastructure exceptions and maps them to one of the subclasses below.
sealed class Failure {
  const Failure(this.message, {this.code});

  /// Safe, user-presentable description. Never contains stack traces or PII.
  final String message;

  /// Stable machine-readable identifier used by the presentation layer (i18n,
  /// analytics, retries). Optional but recommended for new failures.
  final String? code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          other.runtimeType == runtimeType &&
          other.message == message &&
          other.code == code;

  @override
  int get hashCode => Object.hash(runtimeType, message, code);

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

/// The backend or a remote dependency rejected or failed the request.
final class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

/// Local persistence failed (read, write, or corruption).
final class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code});
}

/// Input violated a business rule before reaching the data layer.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Authentication failed, expired, or is required for the operation.
final class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}
