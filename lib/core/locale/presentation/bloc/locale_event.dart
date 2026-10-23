import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

sealed class LocaleEvent extends Equatable {
  const LocaleEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadLocale extends LocaleEvent {
  const LoadLocale();
}

final class ChangeLocale extends LocaleEvent {
  const ChangeLocale(this.locale);

  final Locale? locale;

  @override
  List<Object?> get props => [locale];
}
