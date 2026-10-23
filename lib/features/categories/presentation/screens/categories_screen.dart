import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';
import '../widgets/category_dialog.dart';

/// CRUD for the shared category catalog.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _showArchived = false;

  Future<void> _add() async {
    final l10n = context.l10n;
    final bloc = context.read<CategoryBloc>();
    final name = await showCategoryNameDialog(context, title: l10n.newCategory);
    if (name != null && name.isNotEmpty) {
      bloc.add(AddCategory(name));
    }
  }

  Future<void> _rename(CategoryEntity category) async {
    final l10n = context.l10n;
    final bloc = context.read<CategoryBloc>();
    final name = await showCategoryNameDialog(
      context,
      title: l10n.renameCategory,
      initialValue: category.name,
    );
    if (name != null && name.isNotEmpty && name != category.name) {
      bloc.add(RenameCategory(id: category.id, name: name));
    }
  }

  Future<void> _archive(CategoryEntity category) async {
    final l10n = context.l10n;
    final bloc = context.read<CategoryBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.archiveCategoryQuestion),
        content: Text(l10n.archiveCategoryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.archiveCategory),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(SetCategoryArchived(id: category.id, archived: true));
    }
  }

  void _restore(CategoryEntity category) {
    context.read<CategoryBloc>().add(
      SetCategoryArchived(id: category.id, archived: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.categoriesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(l10n.addCategory),
      ),
      body: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          return switch (state) {
            CategoryInitial() || CategoryLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            CategoryFailure(:final message) => _CategoriesError(
              message: message,
              onRetry: () =>
                  context.read<CategoryBloc>().add(const LoadCategories()),
            ),
            CategoryEmpty(:final error) => _CategoriesEmpty(
              error: error,
              onAdd: _add,
            ),
            CategoryLoaded(:final categories, :final error) => _CategoriesList(
              categories: categories,
              error: error,
              showArchived: _showArchived,
              onToggleArchived: (value) =>
                  setState(() => _showArchived = value),
              onRename: _rename,
              onArchive: _archive,
              onRestore: _restore,
            ),
          };
        },
      ),
    );
  }
}

class _CategoriesList extends StatelessWidget {
  const _CategoriesList({
    required this.categories,
    required this.error,
    required this.showArchived,
    required this.onToggleArchived,
    required this.onRename,
    required this.onArchive,
    required this.onRestore,
  });

  final List<CategoryEntity> categories;
  final String? error;
  final bool showArchived;
  final ValueChanged<bool> onToggleArchived;
  final ValueChanged<CategoryEntity> onRename;
  final ValueChanged<CategoryEntity> onArchive;
  final ValueChanged<CategoryEntity> onRestore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final archivedCount = categories.where((item) => item.isArchived).length;
    final visible = showArchived
        ? categories
        : categories.where((item) => !item.isArchived).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.categoriesDescription,
            style: theme.textTheme.bodySmall,
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _ErrorBanner(message: error!),
          ),
        SwitchListTile(
          value: showArchived,
          onChanged: archivedCount == 0 ? null : onToggleArchived,
          title: Text(l10n.showArchived),
          secondary: const Icon(Icons.inventory_2_outlined),
        ),
        for (final category in visible)
          ListTile(
            leading: Icon(
              category.isArchived
                  ? Icons.inventory_2_outlined
                  : Icons.label_outline,
            ),
            title: Text(category.name),
            subtitle: category.isArchived
                ? Text(
                    l10n.archived,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : null,
            trailing: PopupMenuButton<String>(
              tooltip: l10n.category,
              onSelected: (action) {
                switch (action) {
                  case 'rename':
                    onRename(category);
                  case 'archive':
                    onArchive(category);
                  case 'restore':
                    onRestore(category);
                }
              },
              itemBuilder: (context) => [
                if (!category.isArchived) ...[
                  PopupMenuItem(
                    value: 'rename',
                    child: Text(l10n.renameCategory),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(l10n.archiveCategory),
                  ),
                ] else
                  PopupMenuItem(
                    value: 'restore',
                    child: Text(l10n.restoreCategory),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesEmpty extends StatelessWidget {
  const _CategoriesEmpty({required this.onAdd, this.error});

  final VoidCallback onAdd;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.label_outline,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(l10n.noCategories, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.noCategoriesBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: error!),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.addCategory),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoriesError extends StatelessWidget {
  const _CategoriesError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
          ],
        ),
      ),
    );
  }
}
