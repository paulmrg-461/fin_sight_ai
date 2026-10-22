import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

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
      appBar: AppBar(title: const Text('Debts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddDebt(context),
        icon: const Icon(Icons.add),
        label: const Text('Add debt'),
      ),
      body: BlocBuilder<DebtBloc, DebtState>(
        builder: (context, state) {
          return switch (state) {
            DebtInitial() || DebtLoading() => const Center(
              child: CircularProgressIndicator(semanticsLabel: 'Loading debts'),
            ),
            DebtFailure(:final message) => _DebtErrorView(
              message: message,
              onRetry: () => context.read<DebtBloc>().add(const LoadDebts()),
            ),
            DebtEmpty() => _DebtEmptyView(onAdd: () => _openAddDebt(context)),
            DebtLoaded(:final debts) => ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              itemCount: debts.length,
              itemBuilder: (context, index) {
                final debt = debts[index];
                return DebtCard(
                  debt: debt,
                  onTap: () => _openDetail(context, debt),
                );
              },
            ),
          };
        },
      ),
    );
  }
}

class _DebtEmptyView extends StatelessWidget {
  const _DebtEmptyView({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text('No debts tracked.', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Add a debt to track balances and project your payoff date.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add debt'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtErrorView extends StatelessWidget {
  const _DebtErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
