import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/sync/domain/entities/sync_entities.dart';
import 'package:fin_sight_ai/features/sync/domain/usecases/sync_usecases.dart';
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_event.dart';
import 'package:fin_sight_ai/features/sync/presentation/bloc/sync_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncNow extends Mock implements SyncNowUseCase {}

class MockGetSyncStatus extends Mock implements GetSyncStatusUseCase {}

void main() {
  late MockSyncNow syncNow;
  late MockGetSyncStatus getStatus;

  const status = SyncStatusEntity(
    pendingCount: 2,
    isConfigured: true,
    lastSyncedAt: null,
  );

  final report = SyncReport(
    pushed: 2,
    pulled: 0,
    conflictsResolved: 0,
    pendingOperations: 0,
    isConfigured: true,
    completedAt: DateTime.utc(2026, 10, 22),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    syncNow = MockSyncNow();
    getStatus = MockGetSyncStatus();
  });

  SyncBloc buildBloc() => SyncBloc(syncNow, getStatus);

  group('SyncBloc', () {
    test('initial state is SyncInitial', () {
      expect(buildBloc().state, const SyncInitial());
    });

    blocTest<SyncBloc, SyncState>(
      'loads the pending status',
      setUp: () {
        when(() => getStatus(any()))
            .thenAnswer((_) async => const Right(status));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadSyncStatus()),
      expect: () => [const SyncLoading(), const SyncIdle(status)],
    );

    blocTest<SyncBloc, SyncState>(
      'emits failure when status cannot be read',
      setUp: () {
        when(() => getStatus(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Queue down.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadSyncStatus()),
      expect: () => [const SyncLoading(), const SyncFailure('Queue down.')],
    );

    blocTest<SyncBloc, SyncState>(
      'runs a sync and reports the result',
      setUp: () {
        when(() => syncNow(any())).thenAnswer((_) async => Right(report));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const SyncNow()),
      expect: () => [const SyncInProgress(), SyncSuccess(report)],
    );

    blocTest<SyncBloc, SyncState>(
      'emits failure when sync fails',
      setUp: () {
        when(() => syncNow(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Offline.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const SyncNow()),
      expect: () => [const SyncInProgress(), const SyncFailure('Offline.')],
    );
  });
}
