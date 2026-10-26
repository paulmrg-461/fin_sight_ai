import 'package:fin_sight_ai/core/l10n/failure_text.dart';
import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<BuildContext> pumpLocale(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    return tester.element(find.byType(Scaffold));
  }

  testWidgets('translates known validation failures', (tester) async {
    final context = await pumpLocale(tester, const Locale('es'));

    expect(
      context.failureText('Amount must be greater than zero.'),
      'El monto debe ser mayor que cero.',
    );
    expect(
      context.failureText('Category is required.'),
      'La categoría es obligatoria.',
    );
    expect(
      context.failureText('The start date must be before the end date.'),
      'La fecha inicial debe ser anterior a la final.',
    );
  });

  testWidgets('translates infrastructure failures by prefix', (tester) async {
    final context = await pumpLocale(tester, const Locale('es'));

    expect(
      context.failureText('Unable to read local transactions.'),
      'No se pudieron leer los datos locales.',
    );
    expect(
      context.failureText('Unable to save the budget locally.'),
      'No se pudieron guardar los datos localmente.',
    );
    expect(
      context.failureText('Could not verify which account owns this device.'),
      'Algo salió mal. Inténtalo de nuevo.',
    );
  });

  testWidgets('keeps unknown messages unchanged', (tester) async {
    final context = await pumpLocale(tester, const Locale('en'));

    expect(
      context.failureText('A brand new domain message.'),
      'A brand new domain message.',
    );
    expect(
      context.failureText('Authentication failed.'),
      'Authentication failed.',
    );
  });
}
