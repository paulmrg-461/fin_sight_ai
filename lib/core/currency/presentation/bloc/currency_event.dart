import 'package:equatable/equatable.dart';

import '../../app_currency.dart';

sealed class CurrencyEvent extends Equatable {
  const CurrencyEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadCurrency extends CurrencyEvent {
  const LoadCurrency();
}

final class ChangeCurrency extends CurrencyEvent {
  const ChangeCurrency(this.currency);

  final AppCurrency currency;

  @override
  List<Object?> get props => [currency];
}
