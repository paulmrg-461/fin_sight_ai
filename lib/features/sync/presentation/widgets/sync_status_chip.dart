import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

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

        final icon = isSyncing
            ? Icons.cloud_sync_outlined
            : hasFailure || !configured
            ? Icons.cloud_off_outlined
            : pending > 0
            ? Icons.cloud_upload_outlined
            : Icons.cloud_done_outlined;

        final tooltip = isSyncing
            ? 'Synchronizing…'
            : !configured
            ? 'Sync offline: Supabase is not configured'
            : hasFailure
            ? 'Sync failed. Tap to retry'
            : pending > 0
            ? 'Sync now ($pending pending)'
            : 'All changes synced';

        return IconButton(
          onPressed: isSyncing
              ? null
              : () => context.read<SyncBloc>().add(const SyncNow()),
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
}
