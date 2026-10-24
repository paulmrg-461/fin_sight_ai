import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';

/// Values captured by the payment dialog.
class ReceivablePaymentRequest {
  const ReceivablePaymentRequest({required this.amount, this.note});

  final double amount;
  final String? note;
}

/// Shows the localized dialog used to record money received.
Future<ReceivablePaymentRequest?> showReceivablePaymentDialog(
  BuildContext context, {
  required double remainingAmount,
}) {
  return showDialog<ReceivablePaymentRequest>(
    context: context,
    builder: (_) => _ReceivablePaymentDialog(remainingAmount: remainingAmount),
  );
}

class _ReceivablePaymentDialog extends StatefulWidget {
  const _ReceivablePaymentDialog({required this.remainingAmount});

  final double remainingAmount;

  @override
  State<_ReceivablePaymentDialog> createState() =>
      _ReceivablePaymentDialogState();
}

class _ReceivablePaymentDialogState extends State<_ReceivablePaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final note = _noteController.text.trim();
    Navigator.of(context).pop(
      ReceivablePaymentRequest(
        amount: double.parse(_amountController.text.trim()),
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.addPayment),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('receivable-payment-amount-field'),
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.paymentAmount,
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || !parsed.isFinite || parsed <= 0) {
                    return l10n.invalidLentAmount;
                  }
                  if (parsed > widget.remainingAmount + 0.001) {
                    return l10n.paymentTooHigh;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('receivable-payment-note-field'),
                controller: _noteController,
                maxLength: 500,
                decoration: InputDecoration(labelText: l10n.noteOptional),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('receivable-payment-submit'),
          onPressed: _submit,
          child: Text(l10n.addPayment),
        ),
      ],
    );
  }
}
