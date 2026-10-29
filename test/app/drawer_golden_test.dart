import 'package:fin_sight_ai/app/main_shell.dart';
import 'package:fin_sight_ai/core/l10n/l10n.dart';
import 'package:fin_sight_ai/core/theme/app_theme.dart';
import 'package:fin_sight_ai/core/theme/theme_controller.dart';
import 'package:fin_sight_ai/features/auth/domain/entities/auth_session.dart';
import 'package:fin_sight_ai/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:fin_sight_ai/features/auth/presentation/bloc/auth_state.dart';
import 'package:fin_sight_ai/features/sync/domain/entities/sync_entities.dart';
import 'package:fin_sight_ai/features/sync/domain/usecases/sync_usecases.dart';
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockSignIn extends Mock implements SignInUseCase {}

class MockSignUp extends Mock implements SignUpUseCase {}

class MockSignOut extends Mock implements SignOutUseCase {}

class MockRestoreSession extends Mock implements RestoreSessionUseCase {}

class MockSyncNow extends Mock implements SyncNowUseCase {}

class MockGetSyncStatus extends Mock implements GetSyncStatusUseCase {}

void main() {
  testWidgets('drawer golden', (tester) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final authBloc =
        AuthBloc(
          MockSignIn(),
          MockSignUp(),
          MockSignOut(),
          MockRestoreSession(),
        )..emit(
          AuthAuthenticated(
            AuthSession(
              accessToken: 'access',
              refreshToken: 'refresh',
              userId: 'user-1',
              email: 'user@example.com',
              expiresAt: DateTime.utc(2026, 12, 1),
            ),
          ),
        );
    final syncBloc = SyncBloc(MockSyncNow(), MockGetSyncStatus())
      ..emit(
        const SyncIdle(
          SyncStatusEntity(
            pendingCount: 0,
            isConfigured: true,
            isAuthenticated: true,
          ),
        ),
      );
    final themeController = ThemeController();
    addTearDown(authBloc.close);
    addTearDown(syncBloc.close);
    addTearDown(themeController.dispose);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<SyncBloc>.value(value: syncBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 340,
              height: 1600,
              child: AppDrawer(
                themeController: themeController,
                currentIndex: 0,
                onPrimarySelected: (_) {},
                onSecondarySelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/branding/logo_mark_512.png'),
        tester.element(find.byType(AppDrawer)),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AppDrawer),
      matchesGoldenFile('goldens/app_drawer.png'),
    );
  });
}
