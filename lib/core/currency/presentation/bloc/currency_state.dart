import 'package:equatable/equatable.dart';

import '../../app_currency.dart';

sealed class CurrencyState extends Equatable {
  const CurrencyState();

  @override
  List<Object?> get props => const [];
}

final class CurrencyInitial extends CurrencyState {
  const CurrencyInitial();
}

final class CurrencyLoaded extends CurrencyState {
  const CurrencyLoaded(this.currency);

  final AppCurrency currency;

  @override
  List<Object?> get props => [currency];
}

final class CurrencyFailure extends CurrencyState {
  const CurrencyFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
