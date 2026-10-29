import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/date_formatters.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/bloc/category_state.dart';
import '../../../categories/presentation/widgets/category_dropdown.dart';
import '../../../wallets/domain/entities/wallet_entity.dart';
import '../../../wallets/presentation/bloc/wallet_bloc.dart';
import '../../../wallets/presentation/bloc/wallet_state.dart';
import '../../../wallets/presentation/widgets/wallet_display_name.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';

/// Bottom-sheet form for creating an income or expense.
class TransactionForm extends StatefulWidget {
  const TransactionForm({super.key, this.initial});

  /// When provided, the form edits this transaction instead of creating one.
  final TransactionEntity? initial;

  bool get isEditing => initial != null;

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _receiptController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  String? _walletId;
  String? _category;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _amountController.text = initial.amount.toStringAsFixed(2);
      _descriptionController.text = initial.description;
      _receiptController.text = initial.receiptImagePath ?? '';
      _type = initial.type;
      _date = initial.date;
      _walletId = initial.walletId;
      _category = initial.category;
      return;
    }

    final categoryState = context.read<CategoryBloc>().state;
    if (categoryState is CategoryLoaded) {
      final active = categoryState.categories
          .where((category) => !category.isArchived)
          .toList();
      if (active.isNotEmpty) {
        _category = active.first.name;
      }
    }

    final walletState = context.read<WalletBloc>().state;
    if (walletState is WalletLoaded) {
      _walletId = walletState.balances
          .firstWhere(
            (balance) => balance.type == WalletType.bank,
            orElse: () => walletState.balances.first,
          )
          .wallet
          .id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  void _submit({bool asCopy = false}) {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final bloc = context.read<TransactionBloc>();
    final navigator = Navigator.of(context);
    final amount = double.parse(_amountController.text.trim());
    final receiptImagePath = _receiptController.text.trim().isEmpty
        ? null
        : _receiptController.text.trim();

    if (asCopy) {
      bloc.add(
        AddTransaction(
          amount: amount,
          type: _type,
          category: _category ?? '',
          description: _descriptionController.text,
          date: DateTime.now(),
          walletId: _walletId,
          receiptImagePath: receiptImagePath,
        ),
      );
    } else if (widget.isEditing) {
      bloc.add(
        UpdateTransaction(
          id: widget.initial!.id,
          amount: amount,
          type: _type,
          category: _category ?? '',
          description: _descriptionController.text,
          date: _date,
          walletId: _walletId,
          receiptImagePath: receiptImagePath,
        ),
      );
    } else {
      bloc.add(
        AddTransaction(
          amount: amount,
          type: _type,
          category: _category ?? '',
          description: _descriptionController.text,
          date: _date,
          walletId: _walletId,
          receiptImagePath: receiptImagePath,
        ),
      );
    }
    navigator.pop();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null && mounted) {
      setState(() => _date = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.isEditing
                          ? context.l10n.editTransaction
                          : context.l10n.newTransaction,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _TypeSelector(
                value: _type,
                onChanged: (value) => setState(() => _type = value),
              ),
              const SizedBox(height: 16),
              BlocBuilder<WalletBloc, WalletState>(
                builder: (context, state) {
                  final balances = state is WalletLoaded
                      ? state.balances
                      : const <WalletBalance>[];
                  if (balances.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      initialValue: _walletId,
                      decoration: InputDecoration(
                        labelText: context.l10n.accountOrCash,
                      ),
                      items: [
                        for (final balance in balances)
                          DropdownMenuItem(
                            value: balance.wallet.id,
                            child: Text(
                              walletDisplayName(context, balance.wallet),
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => _walletId = value),
                    ),
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.l10n.amount.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                      validator: (value) {
                        final amount = double.tryParse(value?.trim() ?? '');
                        if (amount == null || !amount.isFinite || amount <= 0) {
                          return context.l10n.enterAmountGreaterThanZero;
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CategoryDropdown(
                value: _category,
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: context.l10n.description,
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(context.l10n.date),
                subtitle: Text(formatDisplayDate(_date)),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _pickDate,
              ),
              TextFormField(
                controller: _receiptController,
                decoration: InputDecoration(
                  labelText: context.l10n.receiptPathOptional,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: Text(
                  widget.isEditing
                      ? context.l10n.saveChanges
                      : context.l10n.saveTransaction,
                ),
              ),
              if (widget.isEditing) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => _submit(asCopy: true),
                  icon: const Icon(Icons.copy_all_rounded),
                  label: Text(context.l10n.saveAsCopy),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.value, required this.onChanged});

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeOption(
            label: context.l10n.expense,
            icon: Icons.arrow_upward_rounded,
            selected: value == TransactionType.expense,
            selectedColor: Theme.of(context).colorScheme.error,
            onTap: () => onChanged(TransactionType.expense),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TypeOption(
            label: context.l10n.incomeShort,
            icon: Icons.arrow_downward_rounded,
            selected: value == TransactionType.income,
            selectedColor: Theme.of(context).colorScheme.primary,
            onTap: () => onChanged(TransactionType.income),
          ),
        ),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? selectedColor
        : theme.colorScheme.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? selectedColor.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? selectedColor.withValues(alpha: 0.55)
                    : theme.colorScheme.outlineVariant,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
