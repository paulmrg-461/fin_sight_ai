import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/main_shell.dart';
import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/failure_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/presentation/bloc/category_state.dart';
import '../../domain/entities/budget_entity.dart';
import '../bloc/budget_bloc.dart';
import '../bloc/budget_event.dart';
import '../bloc/budget_state.dart';

/// Monthly budgets with spending progress.
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  Future<void> _addBudget(BuildContext context, List<String> categories) async {
    final catalog = switch (context.read<CategoryBloc>().state) {
      CategoryLoaded(:final categories) =>
        categories
            .where((category) => !category.isArchived)
            .map((category) => category.name),
      _ => const <String>[],
    };
    final suggestions = {...categories, ...catalog}.toList()..sort();
    final result = await showDialog<(String, double)>(
      context: context,
      builder: (_) => _AddBudgetDialog(categories: suggestions),
    );
    if (result == null || !context.mounted) {
      return;
    }
    context.read<BudgetBloc>().add(
      AddBudget(category: result.$1, monthlyLimit: result.$2),
    );
  }

  List<String> _suggestions(BuildContext context, List<String> categories) {
    final catalog = switch (context.read<CategoryBloc>().state) {
      CategoryLoaded(:final categories) =>
        categories
            .where((category) => !category.isArchived)
            .map((category) => category.name),
      _ => const <String>[],
    };
    return {...categories, ...catalog}.toList()..sort();
  }

  Future<void> _editBudget(
    BuildContext context,
    BudgetProgress item,
    List<String> categories,
  ) async {
    final suggestions = _suggestions(context, categories);
    final result = await showDialog<(String, double)>(
      context: context,
      builder: (_) => _AddBudgetDialog(
        categories: suggestions,
        initialCategory: item.budget.category,
        initialLimit: item.budget.monthlyLimit,
      ),
    );
    if (result == null || !context.mounted) {
      return;
    }
    context.read<BudgetBloc>().add(
      UpdateBudget(
        id: item.budget.id,
        category: result.$1,
        monthlyLimit: result.$2,
        month: item.budget.month,
      ),
    );
  }

  Future<void> _deleteBudget(BuildContext context, BudgetProgress item) async {
    final l10n = context.l10n;
    final bloc = context.read<BudgetBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteBudgetQuestion),
        content: Text(l10n.deleteBudgetBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(DeleteBudget(item.budget.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppMenuButton(),
        title: Text(context.l10n.budgets),
      ),
      body: BlocBuilder<BudgetBloc, BudgetState>(
        builder: (context, state) {
          return switch (state) {
            BudgetInitial() || BudgetLoading() => Center(
              child: CircularProgressIndicator(
                semanticsLabel: context.l10n.loading,
              ),
            ),
            BudgetFailure(:final message) => AppErrorState(
              message: context.failureText(message),
              onRetry: () =>
                  context.read<BudgetBloc>().add(const LoadBudgets()),
            ),
            BudgetEmpty(
              :final categories,
              :final month,
              :final previousBudgetCount,
            ) =>
              AppContent(
                maxWidth: 720,
                child: Column(
                  children: [
                    _MonthSelector(month: month ?? DateTime.now()),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppEmptyState(
                              icon: Icons.pie_chart_rounded,
                              title: context.l10n.noBudgetsYet,
                              message: context.l10n.noBudgetsBody,
                              actionLabel: context.l10n.addBudget,
                              onAction: () => _addBudget(context, categories),
                            ),
                            if (previousBudgetCount > 0) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => context.read<BudgetBloc>().add(
                                  const CopyPreviousBudgets(),
                                ),
                                icon: const Icon(Icons.copy_all_rounded),
                                label: Text(context.l10n.copyPreviousBudgets),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            BudgetLoaded(:final progress, :final categories, :final month) =>
              AppContent(
                padding: EdgeInsets.zero,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    _MonthSelector(month: month ?? DateTime.now()),
                    const SizedBox(height: 8),
                    _BudgetHero(progress: progress),
                    const SizedBox(height: 16),
                    for (final item in progress)
                      _BudgetCard(
                        progress: item,
                        onTap: () => _editBudget(context, item, categories),
                        onDelete: () => _deleteBudget(context, item),
                      ),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: () => _addBudget(context, categories),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(context.l10n.addAnotherBudget),
                    ),
                  ],
                ),
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
        label: Text(context.l10n.addBudget),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.month});

  final DateTime month;

  void _change(BuildContext context, int offset) {
    context.read<BudgetBloc>().add(
      ChangeBudgetMonth(DateTime(month.year, month.month + offset)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = MaterialLocalizations.of(context)
        .formatMonthYear(DateTime(month.year, month.month));
    return Row(
      children: [
        IconButton(
          onPressed: () => _change(context, -1),
          tooltip: context.l10n.previousMonth,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _change(context, 1),
          tooltip: context.l10n.nextMonth,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _BudgetHero extends StatelessWidget {
  const _BudgetHero({required this.progress});

  final List<BudgetProgress> progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSpent = progress.fold<double>(
      0,
      (sum, item) => sum + item.spent,
    );
    final totalLimit = progress.fold<double>(
      0,
      (sum, item) => sum + item.budget.monthlyLimit,
    );
    final ratio = totalLimit <= 0
        ? 0.0
        : (totalSpent / totalLimit).clamp(0.0, 1.0);
    final over = totalSpent > totalLimit;

    return BrandGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.monthlyBudgetSummary,
            style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(
                totalSpent,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '/ ${context.l10n.limitLabel}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.budgetCategoriesCount(progress.length),
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              color: over ? AppColors.danger : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.progress,
    required this.onTap,
    required this.onDelete,
  });

  final BudgetProgress progress;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = progress.budget;
    final overBudget = progress.isOverBudget;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MoneyText(
                        progress.spent,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: overBudget
                              ? AppColors.danger
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(' / ', style: theme.textTheme.labelLarge),
                      MoneyText(
                        budget.monthlyLimit,
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: context.l10n.deleteBudget,
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
                  semanticsLabel: context.l10n.budgetUsage(budget.category),
                  semanticsValue: '${(progress.percentage * 100).round()}%',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    overBudget ? context.l10n.overBudgetBy : '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: overBudget ? AppColors.danger : null,
                    ),
                  ),
                  MoneyText(
                    overBudget ? -progress.remaining : progress.remaining,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: overBudget
                          ? AppColors.danger
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (!overBudget)
                    Text(
                      ' remaining',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddBudgetDialog extends StatefulWidget {
  const _AddBudgetDialog({
    required this.categories,
    this.initialCategory,
    this.initialLimit,
  });

  final List<String> categories;
  final String? initialCategory;
  final double? initialLimit;

  @override
  State<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<_AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _limitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _categoryController.text = widget.initialCategory!;
    }
    if (widget.initialLimit != null) {
      _limitController.text = widget.initialLimit!.toStringAsFixed(2);
    }
  }

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
      title: Text(
        widget.initialCategory == null
            ? context.l10n.newBudget
            : context.l10n.editBudget,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _categoryController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: context.l10n.category),
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? context.l10n.categoryRequired
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
              decoration: InputDecoration(
                labelText: context.l10n.monthlyLimit,
                prefixText: '\$ ',
              ),
              validator: (value) {
                final parsed = double.tryParse(value?.trim() ?? '');
                if (parsed == null || !parsed.isFinite || parsed <= 0) {
                  return context.l10n.limitGreaterThanZero;
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
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            widget.initialCategory == null
                ? context.l10n.saveBudget
                : context.l10n.saveChanges,
          ),
        ),
      ],
    );
  }
}
