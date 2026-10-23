import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_state.dart';
import 'category_dialog.dart';

/// Category selector backed by the shared catalog.
class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.validator,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        final categories = switch (state) {
          CategoryLoaded(:final categories) =>
            categories.where((category) => !category.isArchived).toList(),
          _ => const <CategoryEntity>[],
        };
        final selected = categories.any((category) => category.name == value)
            ? value
            : null;

        return DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.l10n.category,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              tooltip: context.l10n.addCategory,
              onPressed: () => showAddCategoryDialog(context),
            ),
          ),
          items: [
            for (final category in categories)
              DropdownMenuItem(
                value: category.name,
                child: Text(category.name),
              ),
          ],
          onChanged: onChanged,
          validator:
              validator ??
              (selectedValue) =>
                  selectedValue == null ? context.l10n.categoryRequired : null,
        );
      },
    );
  }
}
