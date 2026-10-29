import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:fin_sight_ai/core/services/link_launcher.dart';
import 'package:fin_sight_ai/features/developer/presentation/screens/developer_info_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class _FakeLauncher implements LinkLauncher {
  _FakeLauncher({this.result = true});

  final bool result;
  final List<String> opened = [];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return result;
  }
}

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    LinkLauncher launcher, {
    String version = '1.0.0',
  }) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      wrap(
        DeveloperInfoScreen(
          launcher: launcher,
          versionLoader: () async => version,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the developer profile, version, and legal notice', (
    tester,
  ) async {
    final launcher = _FakeLauncher();
    await pumpScreen(tester, launcher, version: '2.3.4+7');

    expect(find.text('DevPaul'), findsOneWidget);
    expect(find.text('Flutter engineer · Product builder'), findsOneWidget);
    expect(find.text('Version 2.3.4+7'), findsOneWidget);
    expect(find.text('About me'), findsOneWidget);
    expect(find.text('Find me online'), findsOneWidget);
    expect(
      find.text('© ${DateTime.now().year} DevPaul. All rights reserved.'),
      findsOneWidget,
    );
    expect(find.byTooltip('GitHub'), findsOneWidget);
    expect(find.byTooltip('LinkedIn'), findsOneWidget);
    expect(find.byTooltip('devpaul.pro'), findsOneWidget);
  });

  testWidgets('opens a social link through the launcher', (tester) async {
    final launcher = _FakeLauncher();
    await pumpScreen(tester, launcher);

    await tester.tap(find.byTooltip('GitHub'));
    await tester.pump();

    expect(launcher.opened, ['https://github.com/paulmrg-461']);
  });

  testWidgets('opens the website from the call to action', (tester) async {
    final launcher = _FakeLauncher();
    await pumpScreen(tester, launcher);

    await tester.ensureVisible(find.text('Visit devpaul.pro'));
    await tester.tap(find.text('Visit devpaul.pro'));
    await tester.pump();

    expect(launcher.opened, ['https://devpaul.pro']);
  });

  testWidgets('shows a message when a link cannot be opened', (tester) async {
    final launcher = _FakeLauncher(result: false);
    await pumpScreen(tester, launcher);

    await tester.tap(find.byTooltip('GitHub'));
    await tester.pumpAndSettle();

    expect(find.text('Could not open the link.'), findsOneWidget);
  });
}
