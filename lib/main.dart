import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'core/di/injection.dart';
import 'core/utils/app_env.dart';
import 'features/debts/presentation/bloc/debt_bloc.dart';
import 'features/ai_coach/presentation/bloc/ai_coach_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/dashboard/presentation/bloc/dashboard_event.dart';
import 'features/debts/presentation/bloc/debt_event.dart';
import 'features/ocr/presentation/bloc/ocr_bloc.dart';
import 'features/ocr/presentation/bloc/ocr_event.dart';
import 'features/sync/presentation/bloc/sync_bloc.dart';
import 'features/sync/presentation/bloc/sync_event.dart';
import 'features/transactions/presentation/bloc/transaction_bloc.dart';
import 'features/transactions/presentation/bloc/transaction_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnv.load();
  await configureDependencies();

  final transactionBloc = getIt<TransactionBloc>()
    ..add(const LoadTransactions());
  final debtBloc = getIt<DebtBloc>()..add(const LoadDebts());
  final ocrBloc = getIt<OcrBloc>()..add(const LoadReceipts());
  final dashboardBloc = getIt<DashboardBloc>()..add(const LoadDashboard());
  final syncBloc = getIt<SyncBloc>()..add(const SyncNow());

  runApp(
    FinSightApp(
      themeController: getIt(),
      router: getIt(),
      transactionBloc: transactionBloc,
      debtBloc: debtBloc,
      ocrBloc: ocrBloc,
      aiCoachBloc: getIt<AiCoachBloc>(),
      dashboardBloc: dashboardBloc,
      syncBloc: syncBloc,
    ),
  );
}
