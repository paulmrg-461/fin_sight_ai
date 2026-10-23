import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../app_currency.dart';
import '../bloc/currency_bloc.dart';
import '../bloc/currency_state.dart';

/// Renders a monetary amount using the active currency preference.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.signed = false,
    this.style,
    this.textAlign,
  });

  final double amount;
  final bool signed;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrencyBloc, CurrencyState>(
      builder: (context, state) {
        final currency = state is CurrencyLoaded
            ? state.currency
            : AppCurrency.cop;
        final value = signed
            ? MoneyFormatter.signed(amount, currency)
            : MoneyFormatter.format(amount, currency);
        return Text(value, style: style, textAlign: textAlign);
      },
    );
  }
}

/// Currency code label for forms and headers.
class CurrencyLabel extends StatelessWidget {
  const CurrencyLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrencyBloc, CurrencyState>(
      builder: (context, state) {
        final currency = state is CurrencyLoaded
            ? state.currency
            : AppCurrency.cop;
        return Text(currency.code);
      },
    );
  }
}
