import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/sync_entities.dart';
import '../repositories/sync_repository.dart';

/// Runs a full synchronization pass.
@lazySingleton
class SyncNowUseCase implements UseCase<SyncReport, NoParams> {
  const SyncNowUseCase(this._repository);

  final SyncRepository _repository;

  @override
  ResultFuture<SyncReport> call(NoParams params) => _repository.syncNow();
}

/// Reads the current synchronization status.
@lazySingleton
class GetSyncStatusUseCase implements UseCase<SyncStatusEntity, NoParams> {
  const GetSyncStatusUseCase(this._repository);

  final SyncRepository _repository;

  @override
  ResultFuture<SyncStatusEntity> call(NoParams params) =>
      _repository.getStatus();
}
