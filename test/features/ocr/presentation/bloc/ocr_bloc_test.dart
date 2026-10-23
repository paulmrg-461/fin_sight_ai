import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/services/receipt_image_store.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/ocr/domain/entities/receipt_entity.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/get_receipts_usecase.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/save_receipt_usecase.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/scan_receipt_usecase.dart';
import 'package:fin_sight_ai/features/ocr/presentation/bloc/ocr_bloc.dart';
import 'package:fin_sight_ai/features/ocr/presentation/bloc/ocr_event.dart';
import 'package:fin_sight_ai/features/ocr/presentation/bloc/ocr_state.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockScanReceipt extends Mock implements ScanReceiptUseCase {}

class MockSaveReceipt extends Mock implements SaveReceiptUseCase {}

class MockGetReceipts extends Mock implements GetReceiptsUseCase {}

class MockAddTransaction extends Mock implements AddTransactionUseCase {}

class MockReceiptImageStore extends Mock implements ReceiptImageStore {}

void main() {
  late MockScanReceipt scanReceipt;
  late MockSaveReceipt saveReceipt;
  late MockGetReceipts getReceipts;
  late MockAddTransaction addTransaction;
  late MockReceiptImageStore imageStore;

  final receipt = ReceiptEntity(
    id: 'receipt-1',
    imagePath: '/tmp/r.jpg',
    merchantName: 'ACME',
    date: DateTime.utc(2026, 10, 22),
    totalAmount: 11.5,
    items: const [ReceiptItem(name: 'Milk', quantity: 1, price: 11.5)],
    currency: 'USD',
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(receipt);
    registerFallbackValue(
      AddTransactionParams(
        amount: 1,
        type: TransactionType.expense,
        category: 'Other',
        description: '',
        date: DateTime.utc(2026),
      ),
    );
  });

  setUp(() {
    scanReceipt = MockScanReceipt();
    saveReceipt = MockSaveReceipt();
    getReceipts = MockGetReceipts();
    addTransaction = MockAddTransaction();
    imageStore = MockReceiptImageStore();
    when(() => imageStore.persist(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as String,
    );
    when(() => imageStore.delete(any())).thenAnswer((_) async {});
  });

  OcrBloc buildBloc() => OcrBloc(
    scanReceipt,
    saveReceipt,
    getReceipts,
    addTransaction,
    imageStore,
  );

  group('OcrBloc', () {
    test('initial state is OcrInitial', () {
      expect(buildBloc().state, const OcrInitial());
    });

    blocTest<OcrBloc, OcrState>(
      'loads saved receipts',
      setUp: () {
        when(() => getReceipts(any()))
            .thenAnswer((_) async => Right([receipt]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadReceipts()),
      expect: () => [
        const OcrLoading(),
        OcrReceiptsLoaded([receipt]),
      ],
    );

    blocTest<OcrBloc, OcrState>(
      'emits empty when there are no receipts',
      setUp: () {
        when(() => getReceipts(any())).thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadReceipts()),
      expect: () => [const OcrLoading(), const OcrEmpty()],
    );

    blocTest<OcrBloc, OcrState>(
      'emits failure when loading receipts fails',
      setUp: () {
        when(() => getReceipts(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Store down.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadReceipts()),
      expect: () => [const OcrLoading(), const OcrFailure('Store down.')],
    );

    blocTest<OcrBloc, OcrState>(
      'scans a receipt successfully',
      setUp: () {
        when(() => scanReceipt(any())).thenAnswer((_) async => Right(receipt));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ScanReceipt('/tmp/r.jpg')),
      expect: () => [const OcrScanning(), OcrScanSuccess(receipt)],
    );

    blocTest<OcrBloc, OcrState>(
      'deletes the persisted image when scanning fails',
      setUp: () {
        when(
          () => scanReceipt(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Unable to scan.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ScanReceipt('/tmp/r.jpg')),
      expect: () => [const OcrScanning(), const OcrFailure('Unable to scan.')],
      verify: (_) {
        verify(() => imageStore.delete('/tmp/r.jpg')).called(1);
      },
    );

    blocTest<OcrBloc, OcrState>(
      'emits failure when the image cannot be persisted',
      setUp: () {
        when(() => imageStore.persist(any())).thenThrow(
          const CacheException('Image missing.', code: 'receipt_image_missing'),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ScanReceipt('/tmp/r.jpg')),
      expect: () => [
        const OcrScanning(),
        const OcrFailure('Unable to prepare the receipt image.'),
      ],
      verify: (_) {
        verifyNever(() => scanReceipt(any()));
      },
    );

    blocTest<OcrBloc, OcrState>(
      'surfaces scan failures',
      setUp: () {
        when(
          () => scanReceipt(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Unable to scan.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const ScanReceipt('/tmp/r.jpg')),
      expect: () => [const OcrScanning(), const OcrFailure('Unable to scan.')],
    );

    blocTest<OcrBloc, OcrState>(
      'saves a scanned receipt and creates an expense transaction',
      setUp: () {
        when(() => saveReceipt(any())).thenAnswer((_) async => Right(receipt));
        when(() => addTransaction(any())).thenAnswer(
          (_) async => Right(
            TransactionEntity(
              id: receipt.id,
              amount: receipt.totalAmount,
              type: TransactionType.expense,
              category: 'Groceries',
              description: receipt.merchantName,
              date: receipt.date,
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        SaveReceipt(receipt, createTransaction: true, category: 'Groceries'),
      ),
      expect: () => [const OcrSaving(), OcrSaved(receipt)],
      verify: (_) {
        final captured =
            verify(() => addTransaction(captureAny())).captured.single
                as AddTransactionParams;
        expect(captured.amount, 11.5);
        expect(captured.type, TransactionType.expense);
        expect(captured.category, 'Groceries');
        expect(captured.description, 'ACME');
      },
    );

    blocTest<OcrBloc, OcrState>(
      'falls back to the Other category when none is selected',
      setUp: () {
        when(() => saveReceipt(any())).thenAnswer((_) async => Right(receipt));
        when(() => addTransaction(any())).thenAnswer(
          (_) async => Right(
            TransactionEntity(
              id: receipt.id,
              amount: receipt.totalAmount,
              type: TransactionType.expense,
              category: 'Other',
              description: receipt.merchantName,
              date: receipt.date,
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(SaveReceipt(receipt, createTransaction: true)),
      expect: () => [const OcrSaving(), OcrSaved(receipt)],
      verify: (_) {
        final captured =
            verify(() => addTransaction(captureAny())).captured.single
                as AddTransactionParams;
        expect(captured.category, 'Other');
      },
    );

    blocTest<OcrBloc, OcrState>(
      'reports a transaction failure after saving the receipt',
      setUp: () {
        when(() => saveReceipt(any())).thenAnswer((_) async => Right(receipt));
        when(() => addTransaction(any())).thenAnswer(
          (_) async => const Left(ValidationFailure('Invalid amount.')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        SaveReceipt(receipt, createTransaction: true, category: 'Groceries'),
      ),
      expect: () => [
        const OcrSaving(),
        OcrTransactionFailure(receipt, 'Invalid amount.'),
      ],
    );

    blocTest<OcrBloc, OcrState>(
      'does not create a transaction when editing an existing receipt',
      setUp: () {
        when(() => saveReceipt(any())).thenAnswer((_) async => Right(receipt));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(SaveReceipt(receipt)),
      expect: () => [const OcrSaving(), OcrSaved(receipt)],
      verify: (_) {
        verifyNever(() => addTransaction(any()));
      },
    );

    blocTest<OcrBloc, OcrState>(
      'surfaces save failures',
      setUp: () {
        when(() => saveReceipt(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Disk full.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(SaveReceipt(receipt)),
      expect: () => [const OcrSaving(), const OcrFailure('Disk full.')],
      verify: (_) {
        verifyNever(() => addTransaction(any()));
      },
    );
  });
}
