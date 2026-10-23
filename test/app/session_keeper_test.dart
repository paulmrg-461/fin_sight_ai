import 'package:fin_sight_ai/app/session_keeper.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/auth/domain/entities/auth_session.dart';
import 'package:fin_sight_ai/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSignIn extends Mock implements SignInUseCase {}

class MockSignUp extends Mock implements SignUpUseCase {}

class MockSignOut extends Mock implements SignOutUseCase {}

class MockRestoreSession extends Mock implements RestoreSessionUseCase {}

void main() {
  late MockRestoreSession restoreSession;
  late AuthBloc authBloc;

  AuthSession sessionWith(Duration validFor) {
    return AuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      userId: 'user-1',
      email: 'user@example.com',
      expiresAt: DateTime.now().add(validFor),
    );
  }

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    restoreSession = MockRestoreSession();
    when(() => restoreSession(any()))
        .thenAnswer((_) async => Right(sessionWith(const Duration(hours: 1))));
    authBloc = AuthBloc(
      MockSignIn(),
      MockSignUp(),
      MockSignOut(),
      restoreSession,
    );
  });

  tearDown(() async {
    await authBloc.close();
  });

  Future<void> pumpKeeper(WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SessionKeeper(authBloc: authBloc, child: const SizedBox()),
      ),
    );
  }

  /// Delivers a lifecycle message the same way the platform would.
  Future<void> sendLifecycle(
    WidgetTester tester,
    AppLifecycleState state,
  ) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/lifecycle',
      const StringCodec().encodeMessage(state.toString()),
      (_) {},
    );
  }

  Future<void> resume(WidgetTester tester) async {
    await sendLifecycle(tester, AppLifecycleState.paused);
    await sendLifecycle(tester, AppLifecycleState.resumed);
    await tester.pump();
  }

  group('sessionRenewalDelay', () {
    final now = DateTime.utc(2026, 10, 23, 12);

    test('fires five minutes before the session expires', () {
      expect(
        sessionRenewalDelay(
          expiresAt: now.add(const Duration(hours: 1)),
          now: now,
        ),
        const Duration(minutes: 55),
      );
    });

    test('fires the lead time before a session with time to spare', () {
      expect(
        sessionRenewalDelay(
          expiresAt: now.add(const Duration(minutes: 12)),
          now: now,
        ),
        const Duration(minutes: 7),
      );
    });

    test('never schedules sooner than five minutes from now', () {
      expect(
        sessionRenewalDelay(
          expiresAt: now.add(const Duration(minutes: 7)),
          now: now,
        ),
        const Duration(minutes: 5),
      );
      expect(
        sessionRenewalDelay(
          expiresAt: now.add(const Duration(minutes: 2)),
          now: now,
        ),
        const Duration(minutes: 5),
      );
      expect(
        sessionRenewalDelay(
          expiresAt: now.subtract(const Duration(days: 1)),
          now: now,
        ),
        const Duration(minutes: 5),
      );
    });
  });

  group('SessionKeeper', () {
    testWidgets('restores the session on resume when authenticated', (
      tester,
    ) async {
      await pumpKeeper(tester);
      authBloc.emit(AuthAuthenticated(sessionWith(const Duration(hours: 1))));
      await tester.pump();

      await resume(tester);

      verify(() => restoreSession(any())).called(1);
    });

    testWidgets('ignores resume when unauthenticated', (tester) async {
      await pumpKeeper(tester);
      authBloc.emit(const AuthUnauthenticated());
      await tester.pump();

      await resume(tester);

      verifyNever(() => restoreSession(any()));
    });

    testWidgets('refreshes when the renewal timer fires', (tester) async {
      await pumpKeeper(tester);
      authBloc.emit(
        AuthAuthenticated(sessionWith(const Duration(minutes: 12))),
      );
      await tester.pump();

      await tester.pump(const Duration(minutes: 7));
      await tester.pump();
      await tester.pump();

      verify(() => restoreSession(any())).called(1);
    });

    testWidgets('cancels the renewal timer when signed out', (tester) async {
      await pumpKeeper(tester);
      authBloc.emit(AuthAuthenticated(sessionWith(const Duration(minutes: 7))));
      await tester.pump();
      authBloc.emit(const AuthUnauthenticated());
      await tester.pump();

      await tester.pump(const Duration(minutes: 10));

      verifyNever(() => restoreSession(any()));
    });

    testWidgets('cancels the renewal timer on dispose', (tester) async {
      await pumpKeeper(tester);
      authBloc.emit(AuthAuthenticated(sessionWith(const Duration(minutes: 7))));
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 10));

      verifyNever(() => restoreSession(any()));
    });
  });
}
