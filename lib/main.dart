import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'core/di/injection.dart';
import 'core/utils/app_env.dart';
import 'features/debts/presentation/bloc/debt_bloc.dart';
import 'features/debts/presentation/bloc/debt_event.dart';
import 'features/transactions/presentation/bloc/transaction_bloc.dart';
import 'features/transactions/presentation/bloc/transaction_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnv.load();
  await configureDependencies();

  final transactionBloc = getIt<TransactionBloc>()
    ..add(const LoadTransactions());
  final debtBloc = getIt<DebtBloc>()..add(const LoadDebts());

  runApp(
    FinSightApp(
      themeController: getIt(),
      router: getIt(),
      transactionBloc: transactionBloc,
      debtBloc: debtBloc,
    ),
  );
}
