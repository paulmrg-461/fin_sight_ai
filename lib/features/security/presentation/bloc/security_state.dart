import 'package:equatable/equatable.dart';

class SecurityState extends Equatable {
  const SecurityState({
    this.loading = true,
    this.enabled = false,
    this.available = false,
  });

  final bool loading;
  final bool enabled;
  final bool available;

  SecurityState copyWith({bool? loading, bool? enabled, bool? available}) {
    return SecurityState(
      loading: loading ?? this.loading,
      enabled: enabled ?? this.enabled,
      available: available ?? this.available,
    );
  }

  @override
  List<Object?> get props => [loading, enabled, available];
}
