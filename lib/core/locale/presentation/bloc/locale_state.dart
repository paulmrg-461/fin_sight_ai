import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

sealed class LocaleState extends Equatable {
  const LocaleState();

  @override
  List<Object?> get props => const [];
}

final class LocaleInitial extends LocaleState {
  const LocaleInitial();
}

final class LocaleLoaded extends LocaleState {
  const LocaleLoaded(this.locale);

  /// `null` means follow the system locale.
  final Locale? locale;

  @override
  List<Object?> get props => [locale];
}

final class LocaleFailure extends LocaleState {
  const LocaleFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
