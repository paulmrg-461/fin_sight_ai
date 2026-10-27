import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../debts/domain/entities/debt_entity.dart';
import '../../../debts/presentation/bloc/debt_bloc.dart';
import '../../../debts/presentation/bloc/debt_state.dart';
import '../../../receivables/domain/entities/receivable_entity.dart';
import '../../../receivables/presentation/bloc/receivable_bloc.dart';
import '../../../receivables/presentation/bloc/receivable_state.dart';
import '../../../savings/domain/entities/savings_goal_entity.dart';
import '../../../savings/presentation/bloc/savings_bloc.dart';
import '../../../savings/presentation/bloc/savings_state.dart';
import '../../../scheduled_payments/domain/entities/scheduled_payment_entity.dart';
import '../../../scheduled_payments/presentation/bloc/scheduled_payment_bloc.dart';
import '../../../scheduled_payments/presentation/bloc/scheduled_payment_state.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_state.dart';

/// Search across the locally loaded finance data.
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(String? value, String query) =>
      (value ?? '').toLowerCase().contains(query);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = _query.trim().toLowerCase();

    final transactions = switch (context.watch<TransactionBloc>().state) {
      TransactionLoaded(:final transactions) =>
        transactions
            .where(
              (item) =>
                  _matches(item.description, query) ||
                  _matches(item.category, query) ||
                  item.amount.toStringAsFixed(2).contains(query),
            )
            .toList(growable: false),
      _ => const <TransactionEntity>[],
    };
    final debts = switch (context.watch<DebtBloc>().state) {
      DebtLoaded(:final debts) =>
        debts
            .where((item) => _matches(item.creditorName, query))
            .toList(growable: false),
      _ => const <DebtEntity>[],
    };
    final goals = switch (context.watch<SavingsBloc>().state) {
      SavingsLoaded(:final goals) =>
        goals
            .where((item) => _matches(item.name, query))
            .toList(growable: false),
      _ => const <SavingsGoalEntity>[],
    };
    final schedules = switch (context.watch<ScheduledPaymentBloc>().state) {
      ScheduledPaymentLoaded(:final payments) =>
        payments
            .where(
              (item) =>
                  _matches(item.name, query) || _matches(item.category, query),
            )
            .toList(growable: false),
      _ => const <ScheduledPaymentEntity>[],
    };
    final receivables = switch (context.watch<ReceivableBloc>().state) {
      ReceivableLoaded(:final receivables) =>
        receivables
            .where((item) => _matches(item.debtorName, query))
            .toList(growable: false),
      _ => const <ReceivableEntity>[],
    };
    final total =
        transactions.length +
        debts.length +
        goals.length +
        schedules.length +
        receivables.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.globalSearch),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: l10n.globalSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
      body: query.isEmpty
          ? AppContent(
              maxWidth: 620,
              child: _Hint(
                title: l10n.globalSearchEmpty,
                body: l10n.globalSearchEmptyBody,
              ),
            )
          : total == 0
          ? AppContent(
              maxWidth: 620,
              child: _Hint(
                title: l10n.globalSearchNoResults,
                body: l10n.globalSearchNoResultsBody,
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (transactions.isNotEmpty) ...[
                  _SectionHeader(l10n.globalSearchTransactions),
                  for (final item in transactions.take(10))
                    ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          item.isIncome ? Icons.south_west : Icons.north_east,
                        ),
                      ),
                      title: Text(
                        item.description.isEmpty
                            ? item.category
                            : item.description,
                      ),
                      subtitle: Text(
                        '${item.category} · '
                        '${formatDisplayDate(item.date)}',
                      ),
                      trailing: MoneyText(item.signedAmount, signed: true),
                      onTap: () => context.goNamed(AppRoutes.transactionsName),
                    ),
                ],
                if (debts.isNotEmpty) ...[
                  _SectionHeader(l10n.debts),
                  for (final item in debts.take(10))
                    ListTile(
                      leading: const Icon(Icons.account_balance_outlined),
                      title: Text(item.creditorName),
                      subtitle: Text(
                        l10n.dueOn(formatDisplayDate(item.dueDate)),
                      ),
                      trailing: MoneyText(item.remainingAmount),
                      onTap: () => context.pushNamed(AppRoutes.debtsName),
                    ),
                ],
                if (goals.isNotEmpty) ...[
                  _SectionHeader(l10n.savingsGoals),
                  for (final item in goals.take(10))
                    ListTile(
                      leading: const Icon(Icons.savings_outlined),
                      title: Text(item.name),
                      subtitle: Text(
                        '${l10n.savedLabel}: '
                        '${item.savedAmount.toStringAsFixed(2)}',
                      ),
                      trailing: MoneyText(item.targetAmount),
                      onTap: () => context.pushNamed(AppRoutes.savingsName),
                    ),
                ],
                if (schedules.isNotEmpty) ...[
                  _SectionHeader(l10n.scheduledPayments),
                  for (final item in schedules.take(10))
                    ListTile(
                      leading: const Icon(Icons.event_repeat),
                      title: Text(item.name),
                      subtitle: Text(item.category),
                      trailing: MoneyText(item.amount),
                      onTap: () =>
                          context.goNamed(AppRoutes.scheduledPaymentsName),
                    ),
                ],
                if (receivables.isNotEmpty) ...[
                  _SectionHeader(l10n.receivablesTitle),
                  for (final item in receivables.take(10))
                    ListTile(
                      leading: const Icon(Icons.handshake_outlined),
                      title: Text(item.debtorName),
                      subtitle: Text(
                        l10n.dueOn(formatDisplayDate(item.dateLent)),
                      ),
                      trailing: MoneyText(item.remainingAmount),
                      onTap: () => context.pushNamed(AppRoutes.receivablesName),
                    ),
                ],
              ],
            ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_rounded,
            size: 44,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
