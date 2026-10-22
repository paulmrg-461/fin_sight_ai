import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

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
      return 'Enter a value greater than zero.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add debt')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _creditorController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Creditor name'),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Creditor name is required.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _totalController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Total amount',
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
              decoration: const InputDecoration(
                labelText: 'Annual interest rate',
                suffixText: '%',
              ),
              validator: (value) {
                final parsed = double.tryParse(value?.trim() ?? '');
                if (parsed == null ||
                    !parsed.isFinite ||
                    parsed < 0 ||
                    parsed > 100) {
                  return 'Enter a rate between 0 and 100.';
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
              decoration: const InputDecoration(
                labelText: 'Minimum monthly payment',
                prefixText: '\$ ',
              ),
              validator: _validatePositive,
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Due date'),
              subtitle: Text(formatDisplayDate(_dueDate)),
              trailing: const Icon(Icons.edit_outlined),
              onTap: _pickDueDate,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Text('Save debt'),
            ),
          ],
        ),
      ),
    );
  }
}
