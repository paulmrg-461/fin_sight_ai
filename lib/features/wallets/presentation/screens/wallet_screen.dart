import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/main_shell.dart';
import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/failure_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../../core/widgets/app_progress_bar.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_states.dart';
import '../../domain/entities/wallet_entity.dart';
import '../bloc/wallet_bloc.dart';
import '../bloc/wallet_event.dart';
import '../bloc/wallet_state.dart';
import '../widgets/wallet_display_name.dart';

/// Bank/cash balances, reconciliation, and transfers.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<WalletBloc>().add(const LoadWallets());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<WalletBloc>().add(const LoadWallets());
    }
  }

  Future<void> _refresh() async {
    context.read<WalletBloc>().add(const LoadWallets());
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

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
        leading: const AppMenuButton(),
        title: Text(context.l10n.moneyTitle),
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          return switch (state) {
            WalletInitial() || WalletLoading() => Center(
              child: CircularProgressIndicator(
                semanticsLabel: context.l10n.loading,
              ),
            ),
            WalletFailure(:final message) => AppErrorState(
              message: context.failureText(message),
              onRetry: () =>
                  context.read<WalletBloc>().add(const LoadWallets()),
            ),
            WalletLoaded(:final balances) => AppContent(
              padding: EdgeInsets.zero,
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    _MoneyHero(total: state.total, balances: balances),
                    const SizedBox(height: 20),
                    AppSectionHeader(
                      title: context.l10n.accounts,
                      subtitle: context.l10n.bankPlusCash,
                    ),
                    for (final balance in balances)
                      _WalletCard(
                        balance: balance,
                        total: state.total,
                        onSetBalance: () => _setBalance(context, balance),
                      ),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: () => _transfer(context, balances),
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: Text(context.l10n.transferBetweenWallets),
                    ),
                  ],
                ),
              ),
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
        label: Text(context.l10n.transfer),
      ),
    );
  }
}

class _MoneyHero extends StatelessWidget {
  const _MoneyHero({required this.total, required this.balances});

  final double total;
  final List<WalletBalance> balances;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bank = balances
        .where((balance) => balance.type == WalletType.bank)
        .fold<double>(0, (sum, balance) => sum + balance.balance);
    final cash = balances
        .where((balance) => balance.type == WalletType.cash)
        .fold<double>(0, (sum, balance) => sum + balance.balance);

    return BrandGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.totalAvailable,
            style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          MoneyText(
            total,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.bankPlusCash,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroWallet(
                  icon: Icons.account_balance_rounded,
                  label: context.l10n.bankAccount,
                  amount: bank,
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: Colors.white.withValues(alpha: 0.20),
              ),
              Expanded(
                child: _HeroWallet(
                  icon: Icons.payments_rounded,
                  label: context.l10n.cash,
                  amount: cash,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroWallet extends StatelessWidget {
  const _HeroWallet({
    required this.icon,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: Colors.white70),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          DefaultTextStyle(
            style:
                theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ) ??
                const TextStyle(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: MoneyText(amount),
          ),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.balance,
    required this.total,
    required this.onSetBalance,
  });

  final WalletBalance balance;
  final double total;
  final VoidCallback onSetBalance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBank = balance.type == WalletType.bank;
    final displayName = walletDisplayName(context, balance.wallet);
    final typeLabel = isBank ? context.l10n.bankAccount : context.l10n.cash;
    final share = total > 0 ? (balance.balance / total).clamp(0.0, 1.0) : 0.0;
    final accent = isBank
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: accent.withValues(alpha: 0.14),
                  child: Icon(
                    isBank
                        ? Icons.account_balance_rounded
                        : Icons.payments_rounded,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (displayName != typeLabel)
                        Text(typeLabel, style: theme.textTheme.bodySmall),
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
                    TextButton.icon(
                      onPressed: onSetBalance,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: Text(context.l10n.setBalance),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppProgressBar(value: share, height: 6, color: accent),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(share * 100).round()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
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
      title: Text(
        context.l10n.setBalanceTitle(
          walletDisplayName(context, widget.balance.wallet),
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${context.l10n.currentBalance}: '
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
              decoration: InputDecoration(
                labelText: context.l10n.actualBalance,
              ),
              validator: (value) {
                final parsed = double.tryParse(value?.trim() ?? '');
                if (parsed == null || !parsed.isFinite || parsed < 0) {
                  return context.l10n.enterValidBalance;
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
          child: Text(context.l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(context.l10n.save)),
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
      title: Text(context.l10n.transferMoney),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _fromWalletId,
              decoration: InputDecoration(labelText: context.l10n.from),
              items: [
                for (final balance in widget.balances)
                  DropdownMenuItem(
                    value: balance.wallet.id,
                    child: Text(walletDisplayName(context, balance.wallet)),
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
              decoration: InputDecoration(labelText: context.l10n.to),
              items: [
                for (final balance in widget.balances)
                  DropdownMenuItem(
                    value: balance.wallet.id,
                    child: Text(walletDisplayName(context, balance.wallet)),
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
              decoration: InputDecoration(labelText: context.l10n.amount),
              validator: (value) {
                final parsed = double.tryParse(value?.trim() ?? '');
                if (parsed == null || !parsed.isFinite || parsed <= 0) {
                  return context.l10n.enterAmountGreaterThanZero;
                }
                if (_fromWalletId == _toWalletId) {
                  return context.l10n.chooseDifferentWallets;
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _note,
              onChanged: (value) => _note = value,
              decoration: InputDecoration(labelText: context.l10n.noteOptional),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(context.l10n.transfer)),
      ],
    );
  }
}
