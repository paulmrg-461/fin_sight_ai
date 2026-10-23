import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/main_shell.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/routing/app_routes.dart';
import '../../domain/entities/scheduled_payment_entity.dart';
import '../bloc/scheduled_payment_bloc.dart';
import '../bloc/scheduled_payment_event.dart';
import '../bloc/scheduled_payment_state.dart';
import '../widgets/scheduled_payment_card.dart';
import '../widgets/scheduled_payment_form.dart';

/// Recurring expenses and their next due dates.
class ScheduledPaymentScreen extends StatelessWidget {
  const ScheduledPaymentScreen({super.key});

  Future<void> _openForm(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ScheduledPaymentForm(),
    );
  }

  Future<void> _delete(
    BuildContext context,
    ScheduledPaymentEntity payment,
  ) async {
    final l10n = context.l10n;
    final bloc = context.read<ScheduledPaymentBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteScheduledPaymentQuestion),
        content: Text(l10n.deleteScheduledPaymentBody),
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
      bloc.add(DeleteScheduledPayment(payment.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: const AppMenuButton(),
        title: Text(l10n.scheduledPayments),
        actions: [
          IconButton(
            icon: const Icon(Icons.label_outline),
            tooltip: l10n.manageCategories,
            onPressed: () => context.pushNamed(AppRoutes.categoriesName),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addScheduledPayment),
      ),
      body: BlocBuilder<ScheduledPaymentBloc, ScheduledPaymentState>(
        builder: (context, state) {
          return switch (state) {
            ScheduledPaymentInitial() || ScheduledPaymentLoading() =>
              const Center(child: CircularProgressIndicator()),
            ScheduledPaymentFailure(:final message) => _ScheduledError(
              message: message,
              onRetry: () => context.read<ScheduledPaymentBloc>().add(
                const LoadScheduledPayments(),
              ),
            ),
            ScheduledPaymentEmpty(:final autoCreated, :final error) =>
              _EmptyScheduled(
                autoCreated: autoCreated,
                error: error,
                onAdd: () => _openForm(context),
              ),
            ScheduledPaymentLoaded(
              :final payments,
              :final autoCreated,
              :final error,
            ) =>
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  Text(
                    l10n.scheduledPaymentsDescription,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  if (autoCreated > 0) ...[
                    _AutoCreatedBanner(count: autoCreated),
                    const SizedBox(height: 12),
                  ],
                  if (error != null) ...[
                    _ErrorBanner(message: error),
                    const SizedBox(height: 12),
                  ],
                  for (final payment in payments)
                    ScheduledPaymentCard(
                      payment: payment,
                      onPayNow: () => context.read<ScheduledPaymentBloc>().add(
                        PayScheduledPayment(payment.id),
                      ),
                      onToggleActive: () =>
                          context.read<ScheduledPaymentBloc>().add(
                            SetScheduledPaymentActive(
                              id: payment.id,
                              isActive: !payment.isActive,
                            ),
                          ),
                      onDelete: () => _delete(context, payment),
                    ),
                ],
              ),
          };
        },
      ),
    );
  }
}

class _AutoCreatedBanner extends StatelessWidget {
  const _AutoCreatedBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.autoCreatedPayments(count),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
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

class _EmptyScheduled extends StatelessWidget {
  const _EmptyScheduled({
    required this.autoCreated,
    required this.onAdd,
    this.error,
  });

  final int autoCreated;
  final String? error;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (autoCreated > 0) ...[
          _AutoCreatedBanner(count: autoCreated),
          const SizedBox(height: 12),
        ],
        if (error != null) ...[
          _ErrorBanner(message: error!),
          const SizedBox(height: 12),
        ],
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.event_repeat,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noScheduledPayments,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.noScheduledPaymentsBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addFirstScheduledPayment),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduledError extends StatelessWidget {
  const _ScheduledError({required this.message, required this.onRetry});

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
