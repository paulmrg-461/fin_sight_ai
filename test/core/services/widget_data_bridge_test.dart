import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/currency_repository.dart';
import 'package:fin_sight_ai/core/services/widget_data_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCurrencyRepository implements CurrencyRepository {
  FakeCurrencyRepository(this.currency);

  AppCurrency currency;

  @override
  Future<AppCurrency> getCurrency() async => currency;

  @override
  Future<void> setCurrency(AppCurrency currency) async {
    this.currency = currency;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(AndroidWidgetDataBridge.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('publishes formatted values for the active currency', () async {
    final bridge = AndroidWidgetDataBridge(
      FakeCurrencyRepository(AppCurrency.cop),
    );

    await bridge.publish(
      DashboardWidgetSnapshot(
        balance: 1234.5,
        monthlyExpenses: 400,
        generatedAt: DateTime.utc(2026, 10, 27, 12),
      ),
    );

    expect(calls, hasLength(1));
    expect(calls.single.method, 'update');
    final arguments = calls.single.arguments as Map<Object?, Object?>;
    expect(
      arguments['balance'],
      MoneyFormatter.format(1234.5, AppCurrency.cop),
    );
    expect(arguments['expenses'], MoneyFormatter.format(400, AppCurrency.cop));
    expect(arguments['currency'], 'COP');
    expect(arguments['updatedAt'], '2026-10-27T12:00:00.000Z');
  });

  test('uses USD formatting when the preference changes', () async {
    final bridge = AndroidWidgetDataBridge(
      FakeCurrencyRepository(AppCurrency.usd),
    );

    await bridge.publish(
      DashboardWidgetSnapshot(
        balance: 1234.5,
        monthlyExpenses: 0,
        generatedAt: DateTime.utc(2026, 10, 27),
      ),
    );

    final arguments = calls.single.arguments as Map<Object?, Object?>;
    expect(
      arguments['balance'],
      MoneyFormatter.format(1234.5, AppCurrency.usd),
    );
    expect(arguments['currency'], 'USD');
  });

  test('ignores platforms without the widget channel', () async {
    messenger.setMockMethodCallHandler(channel, null);
    final bridge = AndroidWidgetDataBridge(
      FakeCurrencyRepository(AppCurrency.usd),
    );

    await expectLater(
      bridge.publish(
        DashboardWidgetSnapshot(
          balance: 1,
          monthlyExpenses: 1,
          generatedAt: DateTime.utc(2026, 10, 27),
        ),
      ),
      completes,
    );
    expect(calls, isEmpty);
  });
}
