import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/failure_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../../core/widgets/app_progress_bar.dart';
import '../../../../core/widgets/app_states.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/usecases/savings_usecases.dart';
import '../bloc/savings_bloc.dart';
import '../bloc/savings_event.dart';
import '../bloc/savings_state.dart';

class SavingsGoalsScreen extends StatelessWidget {
  const SavingsGoalsScreen({super.key});

  Future<void> _createGoal(BuildContext context) async {
    final result = await showDialog<(String, double, DateTime?)>(
      context: context,
      builder: (_) => const _GoalDialog(),
    );
    if (result == null || !context.mounted) {
      return;
    }
    context.read<SavingsBloc>().add(
      CreateSavingsGoalEvent(
        CreateSavingsGoalParams(
          name: result.$1,
          targetAmount: result.$2,
          targetDate: result.$3,
        ),
      ),
    );
  }

  Future<void> _editGoal(BuildContext context, SavingsGoalEntity goal) async {
    final result = await showDialog<(String, double, DateTime?)>(
      context: context,
      builder: (_) => _GoalDialog(initial: goal),
    );
    if (result == null || !context.mounted) {
      return;
    }
    context.read<SavingsBloc>().add(
      UpdateSavingsGoalEvent(
        UpdateSavingsGoalParams(
          id: goal.id,
          name: result.$1,
          targetAmount: result.$2,
          targetDate: result.$3,
        ),
      ),
    );
  }

  Future<void> _addMoney(BuildContext context, SavingsGoalEntity goal) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => const _ContributionDialog(),
    );
    if (amount == null || !context.mounted) {
      return;
    }
    context.read<SavingsBloc>().add(
      AddSavingsContributionEvent(
        AddSavingsContributionParams(goalId: goal.id, amount: amount),
      ),
    );
  }

  Future<void> _delete(BuildContext context, SavingsGoalEntity goal) async {
    final l10n = context.l10n;
    final bloc = context.read<SavingsBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteSavingsGoalQuestion),
        content: Text(l10n.deleteSavingsGoalBody),
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
      bloc.add(DeleteSavingsGoalEvent(goal.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.savingsGoals)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createGoal(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.newSavingsGoal),
      ),
      body: BlocBuilder<SavingsBloc, SavingsState>(
        builder: (context, state) {
          return switch (state) {
            SavingsInitial() || SavingsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            SavingsFailure(:final message) => AppErrorState(
              message: context.failureText(message),
              onRetry: () =>
                  context.read<SavingsBloc>().add(const LoadSavingsGoals()),
            ),
            SavingsEmpty() => AppContent(
              maxWidth: 620,
              child: AppEmptyState(
                icon: Icons.savings_outlined,
                title: l10n.noSavingsGoals,
                message: l10n.noSavingsGoalsBody,
                actionLabel: l10n.addFirstGoal,
                onAction: () => _createGoal(context),
              ),
            ),
            SavingsLoaded(:final goals) => AppContent(
              padding: EdgeInsets.zero,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  Text(
                    l10n.savingsGoalsDescription,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  _SavingsHero(goals: goals),
                  const SizedBox(height: 16),
                  for (final goal in goals)
                    _GoalCard(
                      goal: goal,
                      onAddMoney: () => _addMoney(context, goal),
                      onEdit: () => _editGoal(context, goal),
                      onDelete: () => _delete(context, goal),
                    ),
                ],
              ),
            ),
          };
        },
      ),
    );
  }
}

class _SavingsHero extends StatelessWidget {
  const _SavingsHero({required this.goals});

  final List<SavingsGoalEntity> goals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final saved = goals.fold<double>(0, (sum, goal) => sum + goal.savedAmount);
    final target = goals.fold<double>(
      0,
      (sum, goal) => sum + goal.targetAmount,
    );
    final progress = target <= 0 ? 0.0 : (saved / target).clamp(0.0, 1.0);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.totalSaved,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(
                  saved,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${l10n.ofTarget} ',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                MoneyText(target, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            AppProgressBar(value: progress, semanticsLabel: l10n.totalSaved),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onAddMoney,
    required this.onEdit,
    required this.onDelete,
  });

  final SavingsGoalEntity goal;
  final VoidCallback onAddMoney;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(goal.name, style: theme.textTheme.titleMedium),
                ),
                if (goal.isComplete)
                  Chip(label: Text(l10n.goalCompleted))
                else
                  PopupMenuButton<String>(
                    key: const ValueKey('goal-actions'),
                    onSelected: (action) =>
                        action == 'edit' ? onEdit() : onDelete(),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.editSavingsGoal),
                      ),
                      PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.savedLabel}: ',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                MoneyText(
                  goal.savedAmount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(' / ', style: theme.textTheme.bodySmall),
                MoneyText(goal.targetAmount, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            AppProgressBar(
              value: goal.progress,
              semanticsLabel: goal.name,
              semanticsValue: '${(goal.progress * 100).round()}%',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (goal.targetDate != null) ...[
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${l10n.goalTargetDate}: '
                    '${formatDisplayDate(goal.targetDate!)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (goal.monthlyNeeded(DateTime.now()) != null) ...[
                  Text(
                    '${l10n.monthlyToReach}: ',
                    style: theme.textTheme.labelSmall,
                  ),
                  MoneyText(
                    goal.monthlyNeeded(DateTime.now())!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: goal.isComplete ? null : onAddMoney,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.addMoney),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalDialog extends StatefulWidget {
  const _GoalDialog({this.initial});

  final SavingsGoalEntity? initial;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _nameController.text = initial.name;
      _targetController.text = initial.targetAmount.toStringAsFixed(2);
      _targetDate = initial.targetDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 90)),
      firstDate: now,
      lastDate: DateTime(now.year + 20),
    );
    if (selected != null) {
      setState(() => _targetDate = selected);
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop((
      _nameController.text.trim(),
      double.parse(_targetController.text.trim()),
      _targetDate,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(
        widget.initial == null ? l10n.newSavingsGoal : l10n.editSavingsGoal,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.goalName),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? l10n.goalNameRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l10n.targetAmount,
                prefixText: '\$ ',
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                return amount == null || !amount.isFinite || amount <= 0
                    ? l10n.targetAmountInvalid
                    : null;
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(l10n.targetDateOptional),
              subtitle: Text(
                _targetDate == null
                    ? l10n.targetDateOptional
                    : formatDisplayDate(_targetDate!),
              ),
              onTap: _pickDate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            widget.initial == null ? l10n.createGoal : l10n.saveChanges,
          ),
        ),
      ],
    );
  }
}

class _ContributionDialog extends StatefulWidget {
  const _ContributionDialog();

  @override
  State<_ContributionDialog> createState() => _ContributionDialogState();
}

class _ContributionDialogState extends State<_ContributionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(double.parse(_controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.addMoney),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.contributionAmount,
            prefixText: '\$ ',
          ),
          validator: (value) {
            final amount = double.tryParse(value?.trim() ?? '');
            return amount == null || !amount.isFinite || amount <= 0
                ? l10n.contributionInvalid
                : null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.addMoney)),
      ],
    );
  }
}
