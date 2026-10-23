import 'dart:io';

import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/currency/hive_currency_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  late Directory tempDirectory;
  late Box<dynamic> box;
  late HiveCurrencyRepository repository;
  var counter = 0;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp('finsight_currency_');
    Hive.init(tempDirectory.path);
  });

  setUp(() async {
    counter++;
    box = await Hive.openBox<dynamic>('settings_$counter');
    repository = HiveCurrencyRepository(box);
  });

  tearDown(() async {
    await box.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  test('defaults to COP', () async {
    expect(await repository.getCurrency(), AppCurrency.cop);
  });

  test('persists USD', () async {
    await repository.setCurrency(AppCurrency.usd);

    expect(await repository.getCurrency(), AppCurrency.usd);
  });

  test('falls back to COP for invalid stored values', () async {
    await box.put('currency', 'eur');

    expect(await repository.getCurrency(), AppCurrency.cop);
  });
}
