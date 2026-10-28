import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:fin_sight_ai/core/theme/app_theme.dart';
import 'package:fin_sight_ai/core/widgets/app_states.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('empty state golden', (tester) async {
    tester.view.physicalSize = const Size(420, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 380,
              child: AppEmptyState(
                icon: Icons.insights_rounded,
                title: 'No transactions yet',
                message: 'Add your first income or expense to unlock spending insights.',
                actionLabel: 'Add a transaction',
                onAction: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AppEmptyState),
      matchesGoldenFile('goldens/app_empty_state.png'),
    );
  });
}
