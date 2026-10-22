import 'package:injectable/injectable.dart';

/// Abstraction over the system clock so time-dependent use cases stay
/// deterministic in tests.
@lazySingleton
class Clock {
  const Clock();

  DateTime now() => DateTime.now();
}
