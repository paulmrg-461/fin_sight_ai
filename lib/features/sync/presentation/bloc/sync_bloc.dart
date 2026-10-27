import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/sync_usecases.dart';
import 'sync_event.dart';
import 'sync_state.dart';

/// Coordinates synchronization and exposes pending/status information.
@injectable
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc(this._syncNow, this._getStatus) : super(const SyncInitial()) {
    on<LoadSyncStatus>(_onLoadStatus);
    on<SyncNow>(_onSyncNow);
  }

  final SyncNowUseCase _syncNow;
  final GetSyncStatusUseCase _getStatus;

  Future<void> _onLoadStatus(
    LoadSyncStatus event,
    Emitter<SyncState> emit,
  ) async {
    emit(const SyncLoading());
    final result = await _getStatus(const NoParams());
    result.fold(
      (failure) => emit(SyncFailure(failure.message)),
      (status) => emit(SyncIdle(status)),
    );
  }

  Future<void> _onSyncNow(SyncNow event, Emitter<SyncState> emit) async {
    emit(const SyncInProgress());
    final result = await _syncNow(const NoParams());
    result.fold((failure) {
      if (kDebugMode) {
        debugPrint('SYNC failed: ${failure.code} — ${failure.message}');
      }
      emit(SyncFailure(failure.message));
    }, (report) => emit(SyncSuccess(report)));
  }
}
