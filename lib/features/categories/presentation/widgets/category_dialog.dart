import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';

/// Asks for a category name. Returns the trimmed name or `null` on cancel.
Future<String?> showCategoryNameDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        _CategoryNameDialog(title: title, initialValue: initialValue),
  );
}

/// Opens the add-category dialog and dispatches [AddCategory].
Future<void> showAddCategoryDialog(BuildContext context) async {
  final bloc = context.read<CategoryBloc>();
  final title = context.l10n.newCategory;
  final name = await showCategoryNameDialog(context, title: title);
  if (name != null && name.isNotEmpty) {
    bloc.add(AddCategory(name));
  }
}

class _CategoryNameDialog extends StatefulWidget {
  const _CategoryNameDialog({required this.title, required this.initialValue});

  final String title;
  final String initialValue;

  @override
  State<_CategoryNameDialog> createState() => _CategoryNameDialogState();
}

class _CategoryNameDialogState extends State<_CategoryNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: context.l10n.categoryName),
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return context.l10n.categoryNameRequired;
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
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
