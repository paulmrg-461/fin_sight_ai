import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/bloc/category_state.dart';
import '../../../categories/presentation/widgets/category_dropdown.dart';
import '../../domain/entities/receipt_entity.dart';
import '../bloc/ocr_bloc.dart';
import '../bloc/ocr_event.dart';
import '../bloc/ocr_state.dart';

/// Shows extracted receipt data and lets the user correct it before saving.
class ReceiptPreviewScreen extends StatefulWidget {
  const ReceiptPreviewScreen({
    super.key,
    required this.receipt,
    this.createTransaction = false,
  });

  final ReceiptEntity receipt;

  /// Creates an expense transaction linked to the receipt when saving.
  final bool createTransaction;

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchantController;
  late final TextEditingController _currencyController;
  late final TextEditingController _totalController;
  late DateTime _date;
  late List<ReceiptItem> _items;
  String? _category;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.receipt.merchantName,
    );
    _currencyController = TextEditingController(text: widget.receipt.currency);
    _totalController = TextEditingController(
      text: widget.receipt.totalAmount.toStringAsFixed(2),
    );
    _date = widget.receipt.date;
    _items = [...widget.receipt.items];
    _category = _defaultCategory();
  }

  String? _defaultCategory() {
    final state = context.read<CategoryBloc>().state;
    if (state is! CategoryLoaded) {
      return null;
    }
    final active = state.categories
        .where((category) => !category.isArchived)
        .toList();
    if (active.isEmpty) {
      return null;
    }
    for (final category in active) {
      if (category.name == 'Other' || category.name == 'Otros') {
        return category.name;
      }
    }
    return active.first.name;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _currencyController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (selected != null && mounted) {
      setState(() => _date = selected);
    }
  }

  Future<void> _addItem() async {
    final item = await _editItem(context);
    if (item != null && mounted) {
      setState(() => _items = [..._items, item]);
    }
  }

  Future<void> _editExistingItem(int index) async {
    final item = await _editItem(context, initial: _items[index]);
    if (item != null && mounted) {
      setState(() {
        final updated = [..._items];
        updated[index] = item;
        _items = updated;
      });
    }
  }

  Future<ReceiptItem?> _editItem(BuildContext context, {ReceiptItem? initial}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: initial?.name ?? '');
    final quantityController = TextEditingController(
      text: (initial?.quantity ?? 1).toString(),
    );
    final priceController = TextEditingController(
      text: (initial?.price ?? 0).toStringAsFixed(2),
    );

    return showDialog<ReceiptItem>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          initial == null ? context.l10n.addItem : context.l10n.editItem,
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: context.l10n.itemName),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? context.l10n.nameRequired
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: context.l10n.quantity),
                validator: _positiveNumber,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.unitPrice,
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  final parsed = double.tryParse(value?.trim() ?? '');
                  if (parsed == null || !parsed.isFinite || parsed < 0) {
                    return context.l10n.enterValidPrice;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (!(formKey.currentState?.validate() ?? false)) {
                return;
              }
              Navigator.of(dialogContext).pop(
                ReceiptItem(
                  name: nameController.text.trim(),
                  quantity: double.parse(quantityController.text.trim()),
                  price: double.parse(priceController.text.trim()),
                ),
              );
            },
            child: Text(context.l10n.save),
          ),
        ],
      ),
    ).whenComplete(() {
      nameController.dispose();
      quantityController.dispose();
      priceController.dispose();
    });
  }

  String? _positiveNumber(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return context.l10n.enterAmountGreaterThanZero;
    }
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final receipt = widget.receipt.copyWith(
      merchantName: _merchantController.text,
      currency: _currencyController.text,
      totalAmount: double.parse(_totalController.text.trim()),
      date: _date,
      items: List<ReceiptItem>.unmodifiable(_items),
    );

    context.read<OcrBloc>().add(
      SaveReceipt(
        receipt,
        createTransaction: widget.createTransaction,
        category: _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OcrBloc, OcrState>(
      listener: (context, state) {
        if (state is OcrSaved) {
          Navigator.of(context).pop(true);
        } else if (state is OcrTransactionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.receiptSavedExpenseFailed)),
          );
          Navigator.of(context).pop(true);
        } else if (state is OcrFailure) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isSaving = state is OcrSaving;

        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.receiptPreview)),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (File(widget.receipt.imagePath).existsSync())
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(widget.receipt.imagePath),
                      height: 180,
                      fit: BoxFit.cover,
                      semanticLabel: context.l10n.receiptImage,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _merchantController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: context.l10n.merchant),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? context.l10n.creditorRequired
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _totalController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: context.l10n.totalAmount,
                        ),
                        validator: _positiveNumber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 96,
                      child: TextFormField(
                        controller: _currencyController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 3,
                        decoration: InputDecoration(
                          labelText: context.l10n.currency,
                          counterText: '',
                        ),
                        validator: (value) {
                          final code = value?.trim().toUpperCase() ?? '';
                          if (!RegExp(r'^[A-Z]{3}$').hasMatch(code)) {
                            return context.l10n.isoCode;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.items,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: Text(context.l10n.addItem),
                    ),
                  ],
                ),
                if (_items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      context.l10n.noItemsExtracted,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  for (var index = 0; index < _items.length; index++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_items[index].name),
                      subtitle: Row(
                        children: [
                          Text('${_items[index].quantity} × '),
                          MoneyText(
                            _items[index].price,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MoneyText(_items[index].lineTotal),
                          IconButton(
                            onPressed: () => _editExistingItem(index),
                            tooltip: context.l10n.editItem,
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => setState(() {
                              final updated = [..._items]..removeAt(index);
                              _items = updated;
                            }),
                            tooltip: context.l10n.removeItem,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                if (widget.createTransaction) ...[
                  CategoryDropdown(
                    value: _category,
                    onChanged: (value) => setState(() => _category = value),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: isSaving ? null : _save,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(context.l10n.saveReceipt),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
