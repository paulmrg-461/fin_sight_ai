import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/ai_coach/presentation/bloc/ai_coach_bloc.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../core/currency/presentation/bloc/currency_bloc.dart';
import '../core/l10n/l10n.dart';
import '../core/locale/presentation/bloc/locale_bloc.dart';
import '../core/locale/presentation/bloc/locale_state.dart';
import '../features/budgets/presentation/bloc/budget_bloc.dart';
import '../features/categories/presentation/bloc/category_bloc.dart';
import '../features/scheduled_payments/presentation/bloc/scheduled_payment_bloc.dart';
import '../features/wallets/presentation/bloc/wallet_bloc.dart';
import '../features/wallets/presentation/bloc/wallet_event.dart';
import '../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../features/dashboard/presentation/bloc/dashboard_event.dart';
import '../features/debts/presentation/bloc/debt_bloc.dart';
import '../features/ocr/presentation/bloc/ocr_bloc.dart';
import '../features/sync/presentation/bloc/sync_bloc.dart';
import '../features/sync/presentation/bloc/sync_state.dart';
import '../features/transactions/presentation/bloc/transaction_bloc.dart';
import '../features/transactions/presentation/bloc/transaction_state.dart';
import 'session_keeper.dart';

/// Root widget: theme binding, routing, and feature-level BLoC providers.
class FinSightApp extends StatelessWidget {
  const FinSightApp({
    super.key,
    required this.themeController,
    required this.router,
    required this.transactionBloc,
    required this.debtBloc,
    required this.ocrBloc,
    required this.aiCoachBloc,
    required this.dashboardBloc,
    required this.syncBloc,
    required this.authBloc,
    required this.budgetBloc,
    required this.walletBloc,
    required this.currencyBloc,
    required this.localeBloc,
    required this.categoryBloc,
    required this.scheduledPaymentBloc,
  });

  final ThemeController themeController;
  final GoRouter router;
  final TransactionBloc transactionBloc;
  final DebtBloc debtBloc;
  final OcrBloc ocrBloc;
  final AiCoachBloc aiCoachBloc;
  final DashboardBloc dashboardBloc;
  final SyncBloc syncBloc;
  final AuthBloc authBloc;
  final BudgetBloc budgetBloc;
  final WalletBloc walletBloc;
  final CurrencyBloc currencyBloc;
  final LocaleBloc localeBloc;
  final CategoryBloc categoryBloc;
  final ScheduledPaymentBloc scheduledPaymentBloc;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TransactionBloc>.value(value: transactionBloc),
        BlocProvider<DebtBloc>.value(value: debtBloc),
        BlocProvider<OcrBloc>.value(value: ocrBloc),
        BlocProvider<AiCoachBloc>.value(value: aiCoachBloc),
        BlocProvider<DashboardBloc>.value(value: dashboardBloc),
        BlocProvider<SyncBloc>.value(value: syncBloc),
        BlocProvider<AuthBloc>.value(value: authBloc),
        BlocProvider<BudgetBloc>.value(value: budgetBloc),
        BlocProvider<WalletBloc>.value(value: walletBloc),
        BlocProvider<CurrencyBloc>.value(value: currencyBloc),
        BlocProvider<LocaleBloc>.value(value: localeBloc),
        BlocProvider<CategoryBloc>.value(value: categoryBloc),
        BlocProvider<ScheduledPaymentBloc>.value(value: scheduledPaymentBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<TransactionBloc, TransactionState>(
            listenWhen: (previous, current) =>
                current is TransactionLoaded || current is TransactionEmpty,
            listener: (context, _) {
              walletBloc.add(const LoadWallets());
              dashboardBloc.add(const RefreshData());
            },
          ),
          BlocListener<SyncBloc, SyncState>(
            listenWhen: (previous, current) => current is SyncSuccess,
            listener: (context, _) {
              walletBloc.add(const LoadWallets());
              dashboardBloc.add(const RefreshData());
            },
          ),
        ],
        child: SessionKeeper(
          authBloc: authBloc,
          child: BlocBuilder<LocaleBloc, LocaleState>(
            builder: (context, localeState) {
              return ListenableBuilder(
                listenable: themeController,
                builder: (context, _) {
                  return MaterialApp.router(
                    onGenerateTitle: (context) => context.l10n.appName,
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.light,
                    darkTheme: AppTheme.dark,
                    themeMode: themeController.themeMode,
                    locale: localeState is LocaleLoaded
                        ? localeState.locale
                        : null,
                    localizationsDelegates: appLocalizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    routerConfig: router,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
