import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/failure_text.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/routing/app_routes.dart';

import '../bloc/sync_bloc.dart';
import '../bloc/sync_event.dart';
import '../bloc/sync_state.dart';

/// App-bar control showing pending changes and triggering a manual sync.
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        final isSyncing = state is SyncInProgress;
        final hasFailure = state is SyncFailure;
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
            : hasFailure || !configured || !authenticated
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
            : hasFailure
            ? context.l10n.syncFailedRetry
            : pending > 0
            ? context.l10n.syncNowPending(pending)
            : context.l10n.allChangesSynced;

        return IconButton(
          onPressed: isSyncing
              ? null
              : () => _handleTap(
                  context,
                  state: state,
                  configured: configured,
                  authenticated: authenticated,
                ),
          tooltip: tooltip,
          icon: isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Badge(
                  isLabelVisible: pending > 0,
                  label: Text('$pending'),
                  child: Icon(icon),
                ),
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
    if (state is SyncFailure) {
      final retry = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.syncFailedTitle),
          content: Text(context.failureText(state.message)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.retry),
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
}
