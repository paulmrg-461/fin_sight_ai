import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/bloc/category_state.dart';
import '../../../categories/presentation/widgets/category_dropdown.dart';
import '../../../wallets/domain/entities/wallet_entity.dart';
import '../../../wallets/presentation/bloc/wallet_bloc.dart';
import '../../../wallets/presentation/bloc/wallet_state.dart';
import '../../../wallets/presentation/widgets/wallet_display_name.dart';
import '../../domain/entities/scheduled_payment_entity.dart';
import '../../domain/usecases/scheduled_payment_usecases.dart';
import '../bloc/scheduled_payment_bloc.dart';
import '../bloc/scheduled_payment_event.dart';

/// Bottom-sheet form for a new scheduled payment.
class ScheduledPaymentForm extends StatefulWidget {
  const ScheduledPaymentForm({super.key});

  @override
  State<ScheduledPaymentForm> createState() => _ScheduledPaymentFormState();
}

class _ScheduledPaymentFormState extends State<ScheduledPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  PaymentFrequency _frequency = PaymentFrequency.monthly;
  DateTime _nextDueDate = DateTime.now();
  late final DateTime _today = DateTime.now();
  String? _category;
  String? _walletId;

  @override
  void initState() {
    super.initState();
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
    if (walletState is WalletLoaded && walletState.balances.isNotEmpty) {
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
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _nextDueDate,
      firstDate: DateTime(_today.year, _today.month, _today.day),
      lastDate: DateTime(_today.year + 10, _today.month, _today.day),
    );
    if (selected != null && mounted) {
      setState(() => _nextDueDate = selected);
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final bloc = context.read<ScheduledPaymentBloc>();
    final navigator = Navigator.of(context);
    bloc.add(
      AddScheduledPayment(
        AddScheduledPaymentParams(
          name: _nameController.text,
          amount: double.parse(_amountController.text.trim()),
          category: _category ?? '',
          frequency: _frequency,
          nextDueDate: _nextDueDate,
          walletId: _walletId,
          notes: _notesController.text,
        ),
      ),
    );
    navigator.pop();
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
              Text(
                context.l10n.newScheduledPayment,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: context.l10n.paymentName,
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? context.l10n.paymentNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.amount,
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || !amount.isFinite || amount <= 0) {
                    return context.l10n.enterAmountGreaterThanZero;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CategoryDropdown(
                value: _category,
                onChanged: (value) => setState(() => _category = value),
              ),
              const SizedBox(height: 16),
              Text(context.l10n.frequency, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<PaymentFrequency>(
                segments: [
                  ButtonSegment(
                    value: PaymentFrequency.monthly,
                    label: Text(context.l10n.monthly),
                  ),
                  ButtonSegment(
                    value: PaymentFrequency.yearly,
                    label: Text(context.l10n.yearly),
                  ),
                ],
                selected: {_frequency},
                onSelectionChanged: (selection) {
                  setState(() => _frequency = selection.first);
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: Text(context.l10n.nextDueDate),
                subtitle: Text(formatDisplayDate(_nextDueDate)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar_outlined),
                  tooltip: context.l10n.nextDueDate,
                  onPressed: _pickDate,
                ),
              ),
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
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: context.l10n.notesOptional,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.event_repeat),
                label: Text(context.l10n.addScheduledPayment),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
