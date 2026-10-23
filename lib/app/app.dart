import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/utils/app_constants.dart';
import '../features/ai_coach/presentation/bloc/ai_coach_bloc.dart';
import '../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../features/debts/presentation/bloc/debt_bloc.dart';
import '../features/ocr/presentation/bloc/ocr_bloc.dart';
import '../features/sync/presentation/bloc/sync_bloc.dart';
import '../features/transactions/presentation/bloc/transaction_bloc.dart';

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
  });

  final ThemeController themeController;
  final GoRouter router;
  final TransactionBloc transactionBloc;
  final DebtBloc debtBloc;
  final OcrBloc ocrBloc;
  final AiCoachBloc aiCoachBloc;
  final DashboardBloc dashboardBloc;
  final SyncBloc syncBloc;

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
      ],
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.themeMode,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
