import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/utils/app_constants.dart';
import '../features/debts/presentation/bloc/debt_bloc.dart';
import '../features/transactions/presentation/bloc/transaction_bloc.dart';

/// Root widget: theme binding, routing, and feature-level BLoC providers.
class FinSightApp extends StatelessWidget {
  const FinSightApp({
    super.key,
    required this.themeController,
    required this.router,
    required this.transactionBloc,
    required this.debtBloc,
  });

  final ThemeController themeController;
  final GoRouter router;
  final TransactionBloc transactionBloc;
  final DebtBloc debtBloc;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TransactionBloc>.value(value: transactionBloc),
        BlocProvider<DebtBloc>.value(value: debtBloc),
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
