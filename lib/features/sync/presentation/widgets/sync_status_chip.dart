import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/failure_text.dart';
import '../../../../core/sync/sync_operation.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/routing/app_routes.dart';

import '../bloc/sync_bloc.dart';
import '../bloc/sync_event.dart';
import '../../domain/entities/sync_entities.dart';
import '../bloc/sync_state.dart';

/// Control showing pending changes and triggering a manual sync.
///
/// Renders an icon button by default and a labelled [ListTile] when
/// [expanded], which is how it appears in the navigation drawer.
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key, this.expanded = false});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        final isSyncing = state is SyncInProgress;
        final hasFailure = state is SyncFailure;
        final entityFailures = state is SyncSuccess
            ? state.report.failures
            : const <SyncEntityFailure>[];
        final hasEntityFailures = entityFailures.isNotEmpty;
        final pending = switch (state) {
          SyncIdle(:final status) => status.pendingCount,
          SyncSuccess(:final report) => report.pendingOperations,
          _ => 0,
        };
        final configured = switch (state) {
          SyncIdle(:final status) => status.isConfigured,
          SyncSuccess(:final report) => report.isConfigured,
          _ => true,
        };
        final authenticated = switch (state) {
          SyncIdle(:final status) => status.isAuthenticated,
          SyncSuccess(:final report) => report.isAuthenticated,
          _ => true,
        };

        final icon = isSyncing
            ? Icons.cloud_sync_outlined
            : hasFailure || hasEntityFailures || !configured || !authenticated
            ? Icons.cloud_off_outlined
            : pending > 0
            ? Icons.cloud_upload_outlined
            : Icons.cloud_done_outlined;

        final tooltip = isSyncing
            ? context.l10n.synchronizing
            : !configured
            ? context.l10n.syncOfflineNotConfigured
            : !authenticated
            ? context.l10n.signInToSync
            : hasFailure || hasEntityFailures
            ? context.l10n.syncFailedRetry
            : pending > 0
            ? context.l10n.syncNowPending(pending)
            : context.l10n.allChangesSynced;

        final onPressed = isSyncing
            ? null
            : () => _handleTap(
                context,
                state: state,
                configured: configured,
                authenticated: authenticated,
              );
        final leading = isSyncing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Badge(
                isLabelVisible: pending > 0,
                label: Text('$pending'),
                child: Icon(icon),
              );

        if (expanded) {
          return ListTile(
            leading: leading,
            title: Text(context.l10n.sync),
            subtitle: Text(tooltip),
            onTap: onPressed,
          );
        }

        return IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          icon: leading,
        );
      },
    );
  }

  Future<void> _handleTap(
    BuildContext context, {
    required SyncState state,
    required bool configured,
    required bool authenticated,
  }) async {
    final bloc = context.read<SyncBloc>();
    if (configured && !authenticated) {
      context.pushNamed(AppRoutes.loginName);
      return;
    }

    final failures = switch (state) {
      SyncSuccess(:final report) => report.failures,
      _ => const <SyncEntityFailure>[],
    };
    if (state is SyncFailure || failures.isNotEmpty) {
      final l10n = context.l10n;
      final retry = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            failures.isEmpty ? l10n.syncFailedTitle : l10n.syncPartialTitle,
          ),
          content: failures.isEmpty
              ? Text(
                  context.failureText(
                    state is SyncFailure ? state.message : '',
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.syncPartialBody),
                    const SizedBox(height: 8),
                    for (final failure in failures)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${_entityLabel(context, failure.entityType)} · '
                          '${failure.code}',
                          style: Theme.of(dialogContext).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
      if (retry == true) {
        bloc.add(const SyncNow());
      }
      return;
    }
    bloc.add(const SyncNow());
  }

  String _entityLabel(BuildContext context, SyncEntityType type) {
    final l10n = context.l10n;
    return switch (type) {
      SyncEntityType.category => l10n.categoriesTitle,
      SyncEntityType.scheduledPayment => l10n.scheduledPayments,
      SyncEntityType.wallet || SyncEntityType.walletTransfer => l10n.money,
      SyncEntityType.savingsGoal => l10n.savingsGoals,
      SyncEntityType.transaction => l10n.transactions,
      SyncEntityType.debt => l10n.debts,
      SyncEntityType.budget => l10n.budgets,
      SyncEntityType.receivable => l10n.receivablesTitle,
      SyncEntityType.receipt => l10n.receiptsLabel,
    };
  }
}
