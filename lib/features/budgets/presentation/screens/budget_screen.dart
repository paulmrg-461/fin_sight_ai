import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/budget_entity.dart';
import '../bloc/budget_bloc.dart';
import '../bloc/budget_event.dart';
import '../bloc/budget_state.dart';

/// Monthly budgets with spending progress.
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  Future<void> _addBudget(BuildContext context, List<String> categories) async {
    final result = await showDialog<(String, double)>(
      context: context,
      builder: (_) => _AddBudgetDialog(categories: categories),
    );
    if (result == null || !context.mounted) {
      return;
    }
    context.read<BudgetBloc>().add(
      AddBudget(category: result.$1, monthlyLimit: result.$2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: BlocBuilder<BudgetBloc, BudgetState>(
        builder: (context, state) {
          return switch (state) {
            BudgetInitial() || BudgetLoading() => const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading budgets',
              ),
            ),
            BudgetFailure(:final message) => _BudgetError(
              message: message,
              onRetry: () =>
                  context.read<BudgetBloc>().add(const LoadBudgets()),
            ),
            BudgetEmpty(:final categories) => _BudgetEmpty(
              onAdd: () => _addBudget(context, categories),
            ),
            BudgetLoaded(:final progress, :final categories) => ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              children: [
                for (final item in progress)
                  _BudgetCard(
                    progress: item,
                    onDelete: () => context.read<BudgetBloc>().add(
                      DeleteBudget(item.budget.id),
                    ),
                  ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => _addBudget(context, categories),
                    icon: const Icon(Icons.add),
                    label: const Text('Add another budget'),
                  ),
                ),
              ],
            ),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final state = context.read<BudgetBloc>().state;
          final categories = switch (state) {
            BudgetLoaded(:final categories) => categories,
            BudgetEmpty(:final categories) => categories,
            _ => const <String>[],
          };
          _addBudget(context, categories);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add budget'),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.progress, required this.onDelete});

  final BudgetProgress progress;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = progress.budget;
    final overBudget = progress.isOverBudget;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    budget.category,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  '\$${progress.spent.toStringAsFixed(2)} / '
                  '\$${budget.monthlyLimit.toStringAsFixed(2)}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: overBudget
                        ? AppColors.danger
                        : theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Delete budget',
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.percentage,
                minHeight: 8,
                color: overBudget ? AppColors.danger : AppColors.emerald,
                semanticsLabel: 'Budget usage for ${budget.category}',
                semanticsValue: '${(progress.percentage * 100).round()}%',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              overBudget
                  ? 'Over budget by '
                        '\$${(-progress.remaining).toStringAsFixed(2)}'
                  : '\$${progress.remaining.toStringAsFixed(2)} remaining',
              style: theme.textTheme.bodySmall?.copyWith(
                color: overBudget
                    ? AppColors.danger
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetEmpty extends StatelessWidget {
  const _BudgetEmpty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text('No budgets yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Set a monthly limit per category and track your progress.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add budget'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetError extends StatelessWidget {
  const _BudgetError({required this.message, required this.onRetry});

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
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBudgetDialog extends StatefulWidget {
  const _AddBudgetDialog({required this.categories});

  final List<String> categories;

  @override
  State<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<_AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _limitController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop((
      _categoryController.text.trim(),
      double.parse(_limitController.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New budget'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _categoryController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Category'),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Category is required.'
                  : null,
            ),
            if (widget.categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final category in widget.categories.take(5))
                      ActionChip(
                        label: Text(category),
                        onPressed: () => _categoryController.text = category,
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(
              controller: _limitController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monthly limit',
                prefixText: '\$ ',
              ),
              validator: (value) {
                final parsed = double.tryParse(value?.trim() ?? '');
                if (parsed == null || !parsed.isFinite || parsed <= 0) {
                  return 'Enter a limit greater than zero.';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save budget')),
      ],
    );
  }
}
