import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/utils/clock.dart';
import 'package:fin_sight_ai/features/ocr/data/datasources/ocr_data_source.dart';
import 'package:fin_sight_ai/features/ocr/data/datasources/receipt_local_data_source.dart';
import 'package:fin_sight_ai/features/ocr/data/models/receipt_model.dart';
import 'package:fin_sight_ai/features/ocr/data/repositories/receipt_repository_impl.dart';
import 'package:fin_sight_ai/features/ocr/domain/entities/receipt_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockOcrDataSource extends Mock implements OcrDataSource {}

class MockReceiptLocalDataSource extends Mock
    implements ReceiptLocalDataSource {}

class FixedClock extends Clock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

void main() {
  final now = DateTime.utc(2026, 10, 22, 12);

  late MockOcrDataSource ocrDataSource;
  late MockReceiptLocalDataSource localDataSource;
  late ReceiptRepositoryImpl repository;

  const sampleText = '''
ACME MARKET
Date: 22/10/2026
Milk 2 x 3.50
Bread 4.50
TOTAL \$11.50
''';

  ReceiptModel buildModel() {
    return ReceiptModel(
      id: 'receipt-1',
      imagePath: '/tmp/r.jpg',
      merchantName: 'ACME',
      date: now,
      totalAmount: 10,
      items: const [],
      currency: 'USD',
    );
  }

  setUpAll(() {
    registerFallbackValue(buildModel());
  });

  setUp(() {
    ocrDataSource = MockOcrDataSource();
    localDataSource = MockReceiptLocalDataSource();
    repository = ReceiptRepositoryImpl(
      localDataSource,
      ocrDataSource,
      clock: FixedClock(now),
    );
  });

  group('ReceiptRepositoryImpl.scanReceipt', () {
    test('extracts a receipt from OCR text', () async {
      when(() => ocrDataSource.recognizeText('/tmp/r.jpg'))
          .thenAnswer((_) async => sampleText);

      final result = await repository.scanReceipt('/tmp/r.jpg');

      final receipt = result.getOrElse((_) => fail('Expected receipt'));
      expect(receipt.imagePath, '/tmp/r.jpg');
      expect(receipt.merchantName, 'ACME MARKET');
      expect(receipt.date, DateTime(2026, 10, 22));
      expect(receipt.totalAmount, 11.5);
      expect(receipt.items, hasLength(2));
      expect(receipt.currency, 'USD');
      expect(receipt.id.trim(), isNotEmpty);
    });

    test('rejects empty OCR text', () async {
      when(() => ocrDataSource.recognizeText(any()))
          .thenAnswer((_) async => '   ');

      final result = await repository.scanReceipt('/tmp/r.jpg');

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(result.getLeft().toNullable()?.code, 'ocr_empty_text');
    });

    test('maps OcrException to ServerFailure', () async {
      when(() => ocrDataSource.recognizeText(any())).thenThrow(
        const OcrException('Engine missing.', code: 'ocr_unavailable'),
      );

      final result = await repository.scanReceipt('/tmp/r.jpg');

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
      expect(result.getLeft().toNullable()?.code, 'ocr_unavailable');
    });

    test('maps unexpected OCR errors to ServerFailure', () async {
      when(() => ocrDataSource.recognizeText(any()))
          .thenThrow(StateError('boom'));

      final result = await repository.scanReceipt('/tmp/r.jpg');

      expect(result.getLeft().toNullable()?.code, 'ocr_failed');
    });
  });

  group('ReceiptRepositoryImpl persistence', () {
    test('saves a receipt and returns the entity', () async {
      when(() => localDataSource.saveReceipt(any())).thenAnswer((_) async {});

      final result = await repository.saveReceipt(
        ReceiptEntity(
          id: 'receipt-1',
          imagePath: '/tmp/r.jpg',
          merchantName: 'ACME',
          date: now,
          totalAmount: 10,
          items: const [],
          currency: 'USD',
        ),
      );

      expect(result.getOrElse((_) => fail('Expected receipt')).id, 'receipt-1');
    });

    test('maps save failures to CacheFailure', () async {
      when(() => localDataSource.saveReceipt(any())).thenThrow(
        const CacheException('Disk full.', code: 'cache_write_failed'),
      );

      final result = await repository.saveReceipt(
        ReceiptEntity(
          id: 'receipt-1',
          imagePath: '/tmp/r.jpg',
          merchantName: 'ACME',
          date: now,
          totalAmount: 10,
          items: const [],
          currency: 'USD',
        ),
      );

      expect(result.getLeft().toNullable()?.code, 'cache_write_failed');
    });

    test('reads and maps receipts', () async {
      when(() => localDataSource.getReceipts())
          .thenAnswer((_) async => [buildModel()]);

      final result = await repository.getReceipts();

      expect(
        result.getOrElse((_) => fail('Expected receipts')).single.id,
        'receipt-1',
      );
    });

    test('maps read failures to CacheFailure', () async {
      when(
        () => localDataSource.getReceipts(),
      ).thenThrow(const CacheException('Corrupt.', code: 'cache_read_failed'));

      final result = await repository.getReceipts();

      expect(result.getLeft().toNullable()?.code, 'cache_read_failed');
    });
  });
}
