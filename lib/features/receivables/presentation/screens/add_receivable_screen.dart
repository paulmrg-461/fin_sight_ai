import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/app_layout.dart';
import '../bloc/receivable_bloc.dart';
import '../bloc/receivable_event.dart';
import '../../domain/entities/receivable_entity.dart';

/// Form for recording money lent to someone.
class AddReceivableScreen extends StatefulWidget {
  const AddReceivableScreen({super.key, this.initial});

  /// When provided, the form edits this receivable instead of creating one.
  final ReceivableEntity? initial;

  bool get isEditing => initial != null;

  @override
  State<AddReceivableScreen> createState() => _AddReceivableScreenState();
}

class _AddReceivableScreenState extends State<AddReceivableScreen> {
  final _formKey = GlobalKey<FormState>();
  final _debtorController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _dateLent = DateTime.now();
  DateTime? _dueDate;
  bool _amountLocked = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) {
      return;
    }
    _debtorController.text = initial.debtorName;
    _amountController.text = initial.totalAmount.toStringAsFixed(2);
    _notesController.text = initial.notes;
    _dateLent = initial.dateLent;
    _dueDate = initial.dueDate;
    _amountLocked = initial.paymentHistory.isNotEmpty;
  }

  @override
  void dispose() {
    _debtorController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateLent() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dateLent,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null && mounted) {
      setState(() => _dateLent = selected);
    }
  }

  Future<void> _pickDueDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _dateLent,
      firstDate: _dateLent,
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

    final bloc = context.read<ReceivableBloc>();
    final navigator = Navigator.of(context);
    final notes = _notesController.text.trim();

    if (widget.isEditing) {
      bloc.add(
        UpdateReceivable(
          id: widget.initial!.id,
          debtorName: _debtorController.text,
          totalAmount: double.parse(_amountController.text.trim()),
          dateLent: _dateLent,
          dueDate: _dueDate,
          notes: notes.isEmpty ? null : notes,
        ),
      );
    } else {
      bloc.add(
        AddReceivable(
          debtorName: _debtorController.text,
          totalAmount: double.parse(_amountController.text.trim()),
          dateLent: _dateLent,
          dueDate: _dueDate,
          notes: notes.isEmpty ? null : notes,
        ),
      );
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? l10n.editReceivable : l10n.addReceivable,
        ),
      ),
      body: AppContent(
        padding: EdgeInsets.zero,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              TextFormField(
                key: const ValueKey('receivable-debtor-field'),
                controller: _debtorController,
                textCapitalization: TextCapitalization.words,
                maxLength: AppConstants.maxDebtorNameLength,
                decoration: InputDecoration(labelText: l10n.debtorName),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? l10n.debtorRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('receivable-amount-field'),
                controller: _amountController,
                readOnly: _amountLocked,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.amountLent,
                  prefixText: '\$ ',
                  helperText: _amountLocked
                      ? l10n.amountLockedAfterPayments
                      : null,
                  helperMaxLines: 2,
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || !parsed.isFinite || parsed <= 0) {
                    return l10n.invalidLentAmount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                key: const ValueKey('receivable-date-lent'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(l10n.dateLent),
                subtitle: Text(formatDisplayDate(_dateLent)),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _pickDateLent,
              ),
              ListTile(
                key: const ValueKey('receivable-due-date'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available_outlined),
                title: Text(l10n.dueDateOptional),
                subtitle: Text(
                  _dueDate == null
                      ? l10n.noDueDate
                      : formatDisplayDate(_dueDate!),
                ),
                trailing: _dueDate == null
                    ? const Icon(Icons.edit_outlined)
                    : IconButton(
                        key: const ValueKey('receivable-clear-due-date'),
                        tooltip: l10n.cancel,
                        onPressed: () => setState(() => _dueDate = null),
                        icon: const Icon(Icons.close),
                      ),
                onTap: _pickDueDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('receivable-notes-field'),
                controller: _notesController,
                maxLength: AppConstants.maxNoteLength,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: l10n.notesOptional),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const ValueKey('receivable-save'),
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: Text(
                  widget.isEditing ? l10n.saveChanges : l10n.saveReceivable,
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
