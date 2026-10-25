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
        final available = categories.map((category) => category.name).toSet();
        final current = value?.trim();
        final selected = current == null || current.isEmpty ? null : current;
        // Keep a value the catalog no longer contains (renamed or archived
        // category) selectable so an existing record can still be saved.
        final hasLegacyValue =
            selected != null && !available.contains(selected);

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
            if (hasLegacyValue)
              DropdownMenuItem(value: selected, child: Text(selected)),
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
