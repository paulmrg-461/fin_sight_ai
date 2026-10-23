import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/auth/domain/entities/auth_session.dart';
import 'package:fin_sight_ai/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_event.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSignIn extends Mock implements SignInUseCase {}

class MockSignUp extends Mock implements SignUpUseCase {}

class MockSignOut extends Mock implements SignOutUseCase {}

class MockRestoreSession extends Mock implements RestoreSessionUseCase {}

void main() {
  late MockSignIn signIn;
  late MockSignUp signUp;
  late MockSignOut signOut;
  late MockRestoreSession restore;

  final session = AuthSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    userId: 'user-1',
    email: 'user@example.com',
    expiresAt: DateTime.utc(2030),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const SignInParams(email: 'a@b.co', password: 'secret1'),
    );
    registerFallbackValue(
      const SignUpParams(email: 'a@b.co', password: 'secret1'),
    );
  });

  setUp(() {
    signIn = MockSignIn();
    signUp = MockSignUp();
    signOut = MockSignOut();
    restore = MockRestoreSession();
  });

  AuthBloc buildBloc() => AuthBloc(signIn, signUp, signOut, restore);

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(buildBloc().state, const AuthInitial());
    });

    blocTest<AuthBloc, AuthState>(
      'restores an authenticated session',
      setUp: () {
        when(() => restore(any())).thenAnswer((_) async => Right(session));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const RestoreAuthSession()),
      expect: () => [const AuthLoading(), AuthAuthenticated(session)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits unauthenticated when there is no session',
      setUp: () {
        when(() => restore(any())).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const RestoreAuthSession()),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits failure when restore fails',
      setUp: () {
        when(() => restore(any()))
            .thenAnswer((_) async => const Left(AuthFailure('Storage down.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const RestoreAuthSession()),
      expect: () => [const AuthLoading(), const AuthError('Storage down.')],
    );

    blocTest<AuthBloc, AuthState>(
      'signs in successfully',
      setUp: () {
        when(() => signIn(any())).thenAnswer((_) async => Right(session));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SignInRequested(email: 'user@example.com', password: 'secret1'),
      ),
      expect: () => [const AuthLoading(), AuthAuthenticated(session)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits failure for invalid credentials',
      setUp: () {
        when(() => signIn(any())).thenAnswer(
          (_) async => const Left(AuthFailure('Invalid email or password.')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SignInRequested(email: 'user@example.com', password: 'bad'),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError('Invalid email or password.'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'signs up successfully',
      setUp: () {
        when(() => signUp(any())).thenAnswer((_) async => Right(session));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SignUpRequested(email: 'user@example.com', password: 'secret1'),
      ),
      expect: () => [const AuthLoading(), AuthAuthenticated(session)],
    );

    blocTest<AuthBloc, AuthState>(
      'signs out',
      setUp: () {
        when(() => signOut(any())).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      seed: () => AuthAuthenticated(session),
      act: (bloc) => bloc.add(const SignOutRequested()),
      expect: () => [const AuthLoading(), const AuthUnauthenticated()],
    );
  });
}
