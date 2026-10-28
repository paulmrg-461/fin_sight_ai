import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:fin_sight_ai/core/services/onboarding_service.dart';
import 'package:fin_sight_ai/features/onboarding/presentation/widgets/onboarding_gate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockOnboardingService extends Mock implements OnboardingService {}

void main() {
  late MockOnboardingService service;

  setUp(() {
    service = MockOnboardingService();
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  testWidgets('shows the tour until the user skips it', (tester) async {
    when(() => service.isCompleted()).thenAnswer((_) async => false);
    when(() => service.complete()).thenAnswer((_) async {});

    await tester.pumpWidget(
      wrap(OnboardingGate(service: service, child: const Text('Dashboard'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to FinSight AI'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    verify(() => service.complete()).called(1);
  });

  testWidgets('goes straight to the app when onboarding is complete', (
    tester,
  ) async {
    when(() => service.isCompleted()).thenAnswer((_) async => true);

    await tester.pumpWidget(
      wrap(OnboardingGate(service: service, child: const Text('Dashboard'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Welcome to FinSight AI'), findsNothing);
  });
}
