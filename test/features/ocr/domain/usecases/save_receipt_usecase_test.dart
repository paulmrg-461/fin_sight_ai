import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/ocr/domain/entities/receipt_entity.dart';
import 'package:fin_sight_ai/features/ocr/domain/repositories/receipt_repository.dart';
import 'package:fin_sight_ai/features/ocr/domain/usecases/save_receipt_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockReceiptRepository extends Mock implements ReceiptRepository {}

void main() {
  late MockReceiptRepository repository;
  late SaveReceiptUseCase useCase;

  ReceiptEntity buildReceipt({
    String id = 'receipt-1',
    String imagePath = '/tmp/r.jpg',
    String merchant = '  ACME  ',
    double total = 10.004,
    String currency = 'usd',
    List<ReceiptItem> items = const [
      ReceiptItem(name: '  Milk  ', quantity: 2, price: 3.999),
    ],
  }) {
    return ReceiptEntity(
      id: id,
      imagePath: imagePath,
      merchantName: merchant,
      date: DateTime.utc(2026, 10, 22),
      totalAmount: total,
      items: items,
      currency: currency,
    );
  }

  setUpAll(() {
    registerFallbackValue(
      ReceiptEntity(
        id: 'fallback',
        imagePath: 'fallback',
        merchantName: 'fallback',
        date: DateTime.utc(2026),
        totalAmount: 1,
        items: const [],
        currency: 'USD',
      ),
    );
  });

  setUp(() {
    repository = MockReceiptRepository();
    useCase = SaveReceiptUseCase(repository);
    when(() => repository.saveReceipt(any())).thenAnswer((invocation) async {
      return Right(invocation.positionalArguments.first as ReceiptEntity);
    });
  });

  group('SaveReceiptUseCase', () {
    test('normalizes merchant, currency, totals, and items', () async {
      final result = await useCase(buildReceipt());

      final saved = result.getOrElse((failure) => fail('Expected receipt'));
      expect(saved.merchantName, 'ACME');
      expect(saved.currency, 'USD');
      expect(saved.totalAmount, 10.0);
      expect(saved.items.single.name, 'Milk');
      expect(saved.items.single.price, 4.0);
    });

    test('generates an id when it is blank', () async {
      final result = await useCase(buildReceipt(id: '   '));

      final saved = result.getOrElse((failure) => fail('Expected receipt'));
      expect(saved.id.trim(), isNotEmpty);
      expect(Uuid.isValidUUID(fromString: saved.id), isTrue);
    });

    test('rejects a blank image path', () async {
      final result = await useCase(buildReceipt(imagePath: '  '));

      expect(result.getLeft().toNullable()?.code, 'missing_image');
    });

    test('rejects a blank merchant', () async {
      final result = await useCase(buildReceipt(merchant: '  '));

      expect(result.getLeft().toNullable()?.code, 'invalid_merchant');
    });

    test('rejects a non-positive total', () async {
      final zero = await useCase(buildReceipt(total: 0));
      final negative = await useCase(buildReceipt(total: -5));

      expect(zero.getLeft().toNullable()?.code, 'invalid_total');
      expect(negative.getLeft().toNullable()?.code, 'invalid_total');
    });

    test('rejects an invalid currency', () async {
      final result = await useCase(buildReceipt(currency: 'US'));

      expect(result.getLeft().toNullable()?.code, 'invalid_currency');
    });

    test('rejects invalid items', () async {
      final blankName = await useCase(
        buildReceipt(
          items: const [ReceiptItem(name: ' ', quantity: 1, price: 1)],
        ),
      );
      final zeroQuantity = await useCase(
        buildReceipt(
          items: const [ReceiptItem(name: 'Milk', quantity: 0, price: 1)],
        ),
      );
      final negativePrice = await useCase(
        buildReceipt(
          items: const [ReceiptItem(name: 'Milk', quantity: 1, price: -1)],
        ),
      );

      expect(blankName.getLeft().toNullable()?.code, 'invalid_item_name');
      expect(
        zeroQuantity.getLeft().toNullable()?.code,
        'invalid_item_quantity',
      );
      expect(negativePrice.getLeft().toNullable()?.code, 'invalid_item_price');
    });

    test('propagates repository failures', () async {
      const failure = CacheFailure('Disk full.');
      when(() => repository.saveReceipt(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(buildReceipt());

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
