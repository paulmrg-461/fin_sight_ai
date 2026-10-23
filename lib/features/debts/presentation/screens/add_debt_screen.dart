import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/date_formatters.dart';
import '../bloc/debt_bloc.dart';
import '../bloc/debt_event.dart';

/// Form for creating a debt.
class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _creditorController = TextEditingController();
  final _totalController = TextEditingController();
  final _interestController = TextEditingController();
  final _minimumPaymentController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _creditorController.dispose();
    _totalController.dispose();
    _interestController.dispose();
    _minimumPaymentController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 50)),
    );
    if (selected != null && mounted) {
      setState(() => _dueDate = selected);
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final bloc = context.read<DebtBloc>();
    final navigator = Navigator.of(context);
    final total = double.parse(_totalController.text.trim());

    bloc.add(
      AddDebt(
        creditorName: _creditorController.text,
        totalAmount: total,
        remainingAmount: total,
        interestRate: double.parse(_interestController.text.trim()),
        minimumPayment: double.parse(_minimumPaymentController.text.trim()),
        dueDate: _dueDate,
      ),
    );
    navigator.pop();
  }

  String? _validatePositive(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return context.l10n.minPaymentGreaterThanZero;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.addDebt)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _creditorController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: context.l10n.creditorName),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? context.l10n.creditorRequired
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _totalController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.totalAmount,
                prefixText: '\$ ',
              ),
              validator: _validatePositive,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _interestController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.annualInterestRate,
                suffixText: '%',
              ),
              validator: (value) {
                final parsed = double.tryParse(value?.trim() ?? '');
                if (parsed == null ||
                    !parsed.isFinite ||
                    parsed < 0 ||
                    parsed > 100) {
                  return context.l10n.rateRange;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minimumPaymentController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.minimumMonthlyPayment,
                prefixText: '\$ ',
              ),
              validator: _validatePositive,
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(context.l10n.dueDate),
              subtitle: Text(formatDisplayDate(_dueDate)),
              trailing: const Icon(Icons.edit_outlined),
              onTap: _pickDueDate,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: Text(context.l10n.saveDebt),
            ),
          ],
        ),
      ),
    );
  }
}
