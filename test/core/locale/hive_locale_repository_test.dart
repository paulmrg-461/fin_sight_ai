import 'dart:io';

import 'package:fin_sight_ai/core/locale/hive_locale_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  late Directory tempDirectory;
  late Box<dynamic> box;
  late HiveLocaleRepository repository;
  var counter = 0;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp('finsight_locale_');
    Hive.init(tempDirectory.path);
  });

  setUp(() async {
    counter++;
    box = await Hive.openBox<dynamic>('settings_$counter');
    repository = HiveLocaleRepository(box);
  });

  tearDown(() async {
    await box.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  test('defaults to system', () async {
    expect(await repository.getLocale(), isNull);
  });

  test('persists English and Spanish', () async {
    await repository.setLocale(const Locale('en'));
    expect(await repository.getLocale(), const Locale('en'));

    await repository.setLocale(const Locale('es'));
    expect(await repository.getLocale(), const Locale('es'));
  });

  test('resets to system', () async {
    await repository.setLocale(const Locale('es'));
    await repository.setLocale(null);

    expect(await repository.getLocale(), isNull);
  });

  test('ignores unsupported stored locales', () async {
    await box.put('locale', 'fr');

    expect(await repository.getLocale(), isNull);
  });
}
