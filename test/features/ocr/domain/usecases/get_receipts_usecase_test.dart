import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/ocr/domain/entities/receipt_entity.dart';
import 'package:fin_sight_ai/features/ocr/domain/repositories/receipt_repository.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/get_receipts_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockReceiptRepository extends Mock implements ReceiptRepository {}

void main() {
  late MockReceiptRepository repository;
  late GetReceiptsUseCase useCase;

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
    useCase = GetReceiptsUseCase(repository);
  });

  group('GetReceiptsUseCase', () {
    test('returns repository receipts', () async {
      when(() => repository.getReceipts())
          .thenAnswer((_) async => Right([receipt]));

      final result = await useCase(const NoParams());

      expect(result.getOrElse((_) => const <ReceiptEntity>[]), [receipt]);
    });

    test('propagates repository failures', () async {
      const failure = CacheFailure('Store down.');
      when(() => repository.getReceipts())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(const NoParams());

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
