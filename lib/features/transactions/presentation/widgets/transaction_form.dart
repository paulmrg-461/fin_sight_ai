import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/date_formatters.dart';
import '../../../wallets/domain/entities/wallet_entity.dart';
import '../../../wallets/presentation/bloc/wallet_bloc.dart';
import '../../../wallets/presentation/bloc/wallet_state.dart';
import '../../domain/entities/transaction_entity.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';

/// Bottom-sheet form for creating an income or expense.
class TransactionForm extends StatefulWidget {
  const TransactionForm({super.key});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _receiptController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  String? _walletId;

  @override
  void initState() {
    super.initState();
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
    _categoryController.dispose();
    _descriptionController.dispose();
    _receiptController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final bloc = context.read<TransactionBloc>();
    final navigator = Navigator.of(context);
    bloc.add(
      AddTransaction(
        amount: double.parse(_amountController.text.trim()),
        type: _type,
        category: _categoryController.text,
        description: _descriptionController.text,
        date: _date,
        walletId: _walletId,
        receiptImagePath: _receiptController.text.trim().isEmpty
            ? null
            : _receiptController.text.trim(),
      ),
    );
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
              Text('New transaction', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() => _type = selection.first);
                },
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
                      decoration: const InputDecoration(
                        labelText: 'Account / cash',
                      ),
                      items: [
                        for (final balance in balances)
                          DropdownMenuItem(
                            value: balance.wallet.id,
                            child: Text(balance.name),
                          ),
                      ],
                      onChanged: (value) => setState(() => _walletId = value),
                    ),
                  );
                },
              ),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || !amount.isFinite || amount <= 0) {
                    return 'Enter an amount greater than zero.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Category is required.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 500,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 4),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Date'),
                subtitle: Text(formatDisplayDate(_date)),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _pickDate,
              ),
              TextFormField(
                controller: _receiptController,
                decoration: const InputDecoration(
                  labelText: 'Receipt image path (optional)',
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('Save transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
