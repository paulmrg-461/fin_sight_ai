import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/routing/app_routes.dart';
import '../../domain/entities/wallet_entity.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';

/// Bank/cash balances, reconciliation, and transfers.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  Future<void> _setBalance(BuildContext context, WalletBalance balance) async {
    final target = await showDialog<double>(
      context: context,
      builder: (_) => _SetBalanceDialog(balance: balance),
    );
    if (target != null && context.mounted) {
      context.read<WalletBloc>().add(
        SetBalance(walletId: balance.wallet.id, target: target),
      );
    }
  }

  Future<void> _transfer(
    BuildContext context,
    List<WalletBalance> balances,
  ) async {
    final result = await showDialog<_TransferDraft>(
      context: context,
      builder: (_) => _TransferDialog(balances: balances),
    );
    if (result != null && context.mounted) {
      context.read<WalletBloc>().add(
        TransferMoney(
          fromWalletId: result.fromWalletId,
          toWalletId: result.toWalletId,
          amount: result.amount,
          note: result.note,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Money'),
        actions: [
          IconButton(
            onPressed: () => context.pushNamed(AppRoutes.settingsName),
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          return switch (state) {
            WalletInitial() || WalletLoading() => const Center(
              child: CircularProgressIndicator(semanticsLabel: 'Loading money'),
            ),
            WalletFailure(:final message) => _WalletError(
              message: message,
              onRetry: () =>
                  context.read<WalletBloc>().add(const LoadWallets()),
            ),
            WalletLoaded(:final balances) => ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _TotalCard(total: state.total),
                const SizedBox(height: 16),
                for (final balance in balances)
                  _WalletCard(
                    balance: balance,
                    onSetBalance: () => _setBalance(context, balance),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _transfer(context, balances),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Transfer between wallets'),
                ),
              ],
            ),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final state = context.read<WalletBloc>().state;
          if (state is WalletLoaded) {
            _transfer(context, state.balances);
          }
        },
        icon: const Icon(Icons.swap_horiz),
        label: const Text('Transfer'),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total available', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            MoneyText(
              total,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text('Bank account + cash', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.balance, required this.onSetBalance});

  final WalletBalance balance;
  final VoidCallback onSetBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBank = balance.type == WalletType.bank;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isBank
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.tertiaryContainer,
              child: Icon(
                isBank
                    ? Icons.account_balance_outlined
                    : Icons.payments_outlined,
                color: isBank
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(balance.name, style: theme.textTheme.titleMedium),
                  Text(
                    isBank ? 'Bank account' : 'Cash',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(
                  balance.balance,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: onSetBalance,
                  child: const Text('Set balance'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletError extends StatelessWidget {
  const _WalletError({required this.message, required this.onRetry});

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

class _SetBalanceDialog extends StatefulWidget {
  const _SetBalanceDialog({required this.balance});

  final WalletBalance balance;

  @override
  State<_SetBalanceDialog> createState() => _SetBalanceDialogState();
}

class _SetBalanceDialogState extends State<_SetBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  // ignore: prefer_final_fields
  late String _value = widget.balance.balance.toStringAsFixed(2);

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(double.parse(_value.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Set ${widget.balance.name} balance'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current balance: '
              '${widget.balance.balance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _value,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) => _value = value,
              decoration: const InputDecoration(labelText: 'Actual balance'),
              validator: (value) {
                final parsed = double.tryParse(value?.trim() ?? '');
                if (parsed == null || !parsed.isFinite || parsed < 0) {
                  return 'Enter a valid balance.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _TransferDraft {
  const _TransferDraft({
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.note,
  });

  final String fromWalletId;
  final String toWalletId;
  final double amount;
  final String note;
}

class _TransferDialog extends StatefulWidget {
  const _TransferDialog({required this.balances});

  final List<WalletBalance> balances;

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  final _formKey = GlobalKey<FormState>();
  String _amount = '';
  String _note = '';
  late String _fromWalletId;
  late String _toWalletId;

  @override
  void initState() {
    super.initState();
    _fromWalletId = widget.balances
        .firstWhere(
          (balance) => balance.type == WalletType.bank,
          orElse: () => widget.balances.first,
        )
        .wallet
        .id;
    _toWalletId = widget.balances
        .firstWhere(
          (balance) => balance.type == WalletType.cash,
          orElse: () => widget.balances.first,
        )
        .wallet
        .id;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      _TransferDraft(
        fromWalletId: _fromWalletId,
        toWalletId: _toWalletId,
        amount: double.parse(_amount.trim()),
        note: _note.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transfer money'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _fromWalletId,
              decoration: const InputDecoration(labelText: 'From'),
              items: [
                for (final balance in widget.balances)
                  DropdownMenuItem(
                    value: balance.wallet.id,
                    child: Text(balance.name),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _fromWalletId = value);
                }
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _toWalletId,
              decoration: const InputDecoration(labelText: 'To'),
              items: [
                for (final balance in widget.balances)
                  DropdownMenuItem(
                    value: balance.wallet.id,
                    child: Text(balance.name),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _toWalletId = value);
                }
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) => _amount = value,
              decoration: const InputDecoration(labelText: 'Amount'),
              validator: (value) {
                final parsed = double.tryParse(value?.trim() ?? '');
                if (parsed == null || !parsed.isFinite || parsed <= 0) {
                  return 'Enter an amount greater than zero.';
                }
                if (_fromWalletId == _toWalletId) {
                  return 'Choose two different wallets.';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _note,
              onChanged: (value) => _note = value,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Transfer')),
      ],
    );
  }
}
