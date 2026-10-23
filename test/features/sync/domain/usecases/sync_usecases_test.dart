import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/sync/domain/entities/sync_entities.dart';
import 'package:fin_sight_ai/features/sync/domain/repositories/sync_repository.dart';
import 'package:fin_sight_ai/features/sync/domain/usecases/sync_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncRepository extends Mock implements SyncRepository {}

void main() {
  late MockSyncRepository repository;

  final report = SyncReport(
    pushed: 2,
    pulled: 1,
    conflictsResolved: 0,
    pendingOperations: 0,
    isConfigured: true,
    completedAt: DateTime.utc(2026, 10, 22),
  );

  const status = SyncStatusEntity(pendingCount: 2, isConfigured: true);

  setUp(() {
    repository = MockSyncRepository();
  });

  test('SyncNowUseCase delegates to the repository', () async {
    when(() => repository.syncNow()).thenAnswer((_) async => Right(report));

    final result = await SyncNowUseCase(repository)(const NoParams());

    expect(result.getOrElse((_) => fail('Expected report')), report);
  });

  test('GetSyncStatusUseCase delegates to the repository', () async {
    when(() => repository.getStatus())
        .thenAnswer((_) async => const Right(status));

    final result = await GetSyncStatusUseCase(repository)(const NoParams());

    expect(result.getOrElse((_) => fail('Expected status')), status);
  });

  test('propagates failures', () async {
    const failure = ServerFailure('Down.');
    when(() => repository.syncNow())
        .thenAnswer((_) async => const Left(failure));

    final result = await SyncNowUseCase(repository)(const NoParams());

    expect(result.getLeft().toNullable(), failure);
  });
}
