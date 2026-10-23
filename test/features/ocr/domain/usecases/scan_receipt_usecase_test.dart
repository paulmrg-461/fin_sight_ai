import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/ocr/domain/entities/receipt_entity.dart';
import 'package:fin_sight_ai/features/ocr/domain/repositories/receipt_repository.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/scan_receipt_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockReceiptRepository extends Mock implements ReceiptRepository {}

void main() {
  late MockReceiptRepository repository;
  late ScanReceiptUseCase useCase;

  final receipt = ReceiptEntity(
    id: 'receipt-1',
    imagePath: '/tmp/r.jpg',
    merchantName: 'Shop',
    date: DateTime.utc(2026, 10, 22),
    totalAmount: 10,
    items: const [],
    currency: 'USD',
  );

  setUp(() {
    repository = MockReceiptRepository();
    useCase = ScanReceiptUseCase(repository);
  });

  group('ScanReceiptUseCase', () {
    test('delegates a trimmed image path to the repository', () async {
      when(() => repository.scanReceipt('/tmp/r.jpg'))
          .thenAnswer((_) async => Right(receipt));

      final result = await useCase('  /tmp/r.jpg  ');

      expect(result.getOrElse((_) => fail('Expected a receipt')), receipt);
      verify(() => repository.scanReceipt('/tmp/r.jpg')).called(1);
    });

    test('rejects a blank image path', () async {
      final result = await useCase('   ');

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(result.getLeft().toNullable()?.code, 'missing_image');
      verifyNever(() => repository.scanReceipt(any()));
    });

    test('propagates repository failures', () async {
      const failure = ServerFailure('OCR failed.', code: 'ocr_failed');
      when(() => repository.scanReceipt('/tmp/r.jpg'))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase('/tmp/r.jpg');

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
