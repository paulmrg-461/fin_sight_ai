import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

import '../currency/app_currency.dart';
import '../currency/currency_repository.dart';

/// Values the Android home-screen widget displays.
class DashboardWidgetSnapshot {
  const DashboardWidgetSnapshot({
    required this.balance,
    required this.monthlyExpenses,
    required this.generatedAt,
  });

  final double balance;
  final double monthlyExpenses;
  final DateTime generatedAt;
}

/// Publishes dashboard values to the platform home-screen widget.
abstract interface class WidgetDataBridge {
  Future<void> publish(DashboardWidgetSnapshot snapshot);
}

/// Android implementation backed by a `MethodChannel` handled in
/// `MainActivity`, which stores the values and refreshes the widget.
@LazySingleton(as: WidgetDataBridge)
class AndroidWidgetDataBridge implements WidgetDataBridge {
  AndroidWidgetDataBridge(this._currency);

  static const String channelName = 'devpaul.fin_sight_ai/widget';

  final CurrencyRepository _currency;
  final MethodChannel _channel = const MethodChannel(channelName);

  @override
  Future<void> publish(DashboardWidgetSnapshot snapshot) async {
    try {
      final currency = await _currency.getCurrency();
      await _channel.invokeMethod<void>('update', <String, String>{
        'balance': MoneyFormatter.format(snapshot.balance, currency),
        'expenses': MoneyFormatter.format(snapshot.monthlyExpenses, currency),
        'currency': currency.code,
        'updatedAt': snapshot.generatedAt.toIso8601String(),
      });
    } catch (_) {
      // Widgets are best effort: unsupported platforms and vendor failures must
      // never affect the ledger.
    }
  }
}
