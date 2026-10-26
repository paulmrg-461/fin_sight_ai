import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/failure_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../../core/widgets/app_states.dart';
import '../../domain/entities/debt_entity.dart';
import '../bloc/debt_bloc.dart';
import '../bloc/debt_event.dart';
import '../bloc/debt_state.dart';
import '../widgets/debt_card.dart';
import 'add_debt_screen.dart';
import 'debt_detail_screen.dart';

/// Lists every debt with repayment progress.
class DebtListScreen extends StatelessWidget {
  const DebtListScreen({super.key});

  void _openAddDebt(BuildContext context) {
    final bloc = context.read<DebtBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            BlocProvider.value(value: bloc, child: const AddDebtScreen()),
      ),
    );
  }

  void _openDetail(BuildContext context, DebtEntity debt) {
    final bloc = context.read<DebtBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: DebtDetailScreen(debtId: debt.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.debts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDebt(context),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addDebt),
      ),
      body: BlocBuilder<DebtBloc, DebtState>(
        builder: (context, state) {
          return switch (state) {
            DebtInitial() || DebtLoading() => Center(
              child: CircularProgressIndicator(
                semanticsLabel: context.l10n.loadingDebts,
              ),
            ),
            DebtFailure(:final message) => AppErrorState(
              message: context.failureText(message),
              onRetry: () => context.read<DebtBloc>().add(const LoadDebts()),
            ),
            DebtEmpty() => AppContent(
              maxWidth: 720,
              child: Center(
                child: AppEmptyState(
                  icon: Icons.account_balance_rounded,
                  title: context.l10n.noDebtsYet,
                  message: context.l10n.noDebtsBody,
                  actionLabel: context.l10n.addDebt,
                  onAction: () => _openAddDebt(context),
                ),
              ),
            ),
            DebtLoaded(:final debts) => AppContent(
              padding: EdgeInsets.zero,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  _DebtHero(debts: debts),
                  const SizedBox(height: 16),
                  for (final debt in debts)
                    DebtCard(
                      debt: debt,
                      onTap: () => _openDetail(context, debt),
                    ),
                ],
              ),
            ),
          };
        },
      ),
    );
  }
}

class _DebtHero extends StatelessWidget {
  const _DebtHero({required this.debts});

  final List<DebtEntity> debts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = debts.where((debt) => !debt.isPaid).toList();
    final total = active.fold<double>(
      0,
      (sum, debt) => sum + debt.remainingAmount,
    );
    return BrandGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.totalDebt,
            style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          MoneyText(
            total,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.activeDebts(active.length),
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
