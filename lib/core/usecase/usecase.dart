import 'package:fpdart/fpdart.dart';

import '../error/failures.dart';

/// Functional result used across every layer boundary.
typedef Result<T> = Either<Failure, T>;

/// Convenience alias for asynchronous results.
typedef ResultFuture<T> = Future<Result<T>>;

/// Contract implemented by every feature use case.
///
/// [T] is the success value; [Params] is the input object. Use [NoParams] for
/// use cases that take no arguments.
abstract interface class UseCase<T, Params> {
  ResultFuture<T> call(Params params);
}

/// Marker input for use cases without parameters.
final class NoParams {
  const NoParams();

  @override
  bool operator ==(Object other) => other is NoParams;

  @override
  int get hashCode => runtimeType.hashCode;
}
