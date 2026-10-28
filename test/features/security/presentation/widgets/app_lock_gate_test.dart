import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:fin_sight_ai/core/services/biometric_service.dart';
import 'package:fin_sight_ai/core/services/security_preferences.dart';
import 'package:fin_sight_ai/features/security/presentation/bloc/security_cubit.dart';
import 'package:fin_sight_ai/features/security/presentation/widgets/app_lock_gate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class FakePreferences implements SecurityPreferences {
  FakePreferences(this.enabled);
  bool enabled;

  @override
  Future<bool> isBiometricEnabled() async => enabled;

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    this.enabled = enabled;
  }
}

class FakeBiometrics implements BiometricService {
  FakeBiometrics({this.available = true, this.result = true});
  bool available;
  bool result;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate() async => result;
}

void main() {
  Widget wrap(SecurityCubit cubit) {
    return BlocProvider<SecurityCubit>.value(
      value: cubit,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AppLockGate(child: const Text('Dashboard')),
      ),
    );
  }

  testWidgets('shows the lock until authentication succeeds', (tester) async {
    final biometrics = FakeBiometrics(result: false);
    final cubit = SecurityCubit(FakePreferences(true), biometrics);
    addTearDown(cubit.close);

    await tester.pumpWidget(wrap(cubit));
    await tester.pumpAndSettle();

    expect(find.text('FinSight AI is locked'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);

    biometrics.result = true;
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('skips locking when the preference is off', (tester) async {
    final cubit = SecurityCubit(FakePreferences(false), FakeBiometrics());
    addTearDown(cubit.close);

    await tester.pumpWidget(wrap(cubit));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('FinSight AI is locked'), findsNothing);
  });

  testWidgets('does not lock when biometrics are unavailable', (tester) async {
    final cubit = SecurityCubit(
      FakePreferences(true),
      FakeBiometrics(available: false),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(wrap(cubit));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
  });
}
