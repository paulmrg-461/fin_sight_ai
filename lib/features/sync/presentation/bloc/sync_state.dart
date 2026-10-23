import 'package:equatable/equatable.dart';

import '../../domain/entities/sync_entities.dart';

/// Base state for synchronization.
sealed class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => const [];
}

final class SyncInitial extends SyncState {
  const SyncInitial();
}

final class SyncLoading extends SyncState {
  const SyncLoading();
}

final class SyncIdle extends SyncState {
  const SyncIdle(this.status);

  final SyncStatusEntity status;

  @override
  List<Object?> get props => [status];
}

final class SyncInProgress extends SyncState {
  const SyncInProgress();
}

final class SyncSuccess extends SyncState {
  const SyncSuccess(this.report);

  final SyncReport report;

  @override
  List<Object?> get props => [report];
}

final class SyncFailure extends SyncState {
  const SyncFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
