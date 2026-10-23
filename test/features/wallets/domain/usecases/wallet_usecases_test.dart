import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/wallets/domain/entities/wallet_entity.dart';
import 'package:fin_sight_ai/features/wallets/domain/repositories/wallet_repository.dart';
import 'package:fin_sight_ai/features/wallets/domain/usecases/wallet_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockWalletRepository extends Mock implements WalletRepository {}

void main() {
  late MockWalletRepository repository;

  const bank = WalletEntity(
    id: 'wallet-bank',
    name: 'Cuenta',
    type: WalletType.bank,
    openingBalance: 0,
  );

  setUpAll(() {
    registerFallbackValue(bank);
  });

  setUp(() {
    repository = MockWalletRepository();
  });

  test('SetWalletBalanceUseCase validates input', () async {
    final missing = await SetWalletBalanceUseCase(repository)(
      const SetWalletBalanceParams(walletId: '  ', target: 10),
    );
    final negative = await SetWalletBalanceUseCase(repository)(
      const SetWalletBalanceParams(walletId: 'bank', target: -1),
    );

    expect(missing.getLeft().toNullable()?.code, 'missing_wallet');
    expect(negative.getLeft().toNullable()?.code, 'invalid_balance');
  });

  test('TransferBetweenWalletsUseCase validates input', () async {
    final same = await TransferBetweenWalletsUseCase(repository)(
      TransferBetweenWalletsParams(
        fromWalletId: 'bank',
        toWalletId: 'bank',
        amount: 10,
        date: DateTime.utc(2026, 10, 2),
      ),
    );
    final zero = await TransferBetweenWalletsUseCase(repository)(
      TransferBetweenWalletsParams(
        fromWalletId: 'bank',
        toWalletId: 'cash',
        amount: 0,
        date: DateTime.utc(2026, 10, 2),
      ),
    );

    expect(same.getLeft().toNullable()?.code, 'same_wallet');
    expect(zero.getLeft().toNullable()?.code, 'invalid_amount');
  });

  test('GetWalletBalancesUseCase delegates', () async {
    when(() => repository.getWalletBalances()).thenAnswer(
      (_) async => Right([WalletBalance(wallet: bank, balance: 10)]),
    );

    final result = await GetWalletBalancesUseCase(repository)(const NoParams());

    expect(result.getOrElse((_) => const <WalletBalance>[]), hasLength(1));
  });

  test('SetWalletBalanceUseCase delegates a valid target', () async {
    when(
      () => repository.setWalletBalance(walletId: 'bank', target: 10),
    ).thenAnswer((_) async => Right(WalletBalance(wallet: bank, balance: 10)));

    final result = await SetWalletBalanceUseCase(repository)(
      const SetWalletBalanceParams(walletId: 'bank', target: 10),
    );

    expect(result.getOrElse((_) => fail('Expected balance')).balance, 10);
  });

  test('transfer rejects missing wallet ids', () async {
    final result = await TransferBetweenWalletsUseCase(repository)(
      TransferBetweenWalletsParams(
        fromWalletId: '',
        toWalletId: 'cash',
        amount: 10,
        date: DateTime.utc(2026, 10, 2),
      ),
    );

    expect(result.getLeft().toNullable()?.code, 'missing_wallet');
  });

  test('transfers through the repository', () async {
    when(
      () => repository.transfer(
        fromWalletId: 'bank',
        toWalletId: 'cash',
        amount: 10,
        date: DateTime.utc(2026, 10, 2),
        note: 'ATM',
      ),
    ).thenAnswer(
      (_) async => Right(
        WalletTransferEntity(
          id: 't-1',
          fromWalletId: 'bank',
          toWalletId: 'cash',
          amount: 10,
          date: DateTime.utc(2026, 10, 2),
          note: 'ATM',
        ),
      ),
    );

    final result = await TransferBetweenWalletsUseCase(repository)(
      TransferBetweenWalletsParams(
        fromWalletId: 'bank',
        toWalletId: 'cash',
        amount: 10,
        date: DateTime.utc(2026, 10, 2),
        note: ' ATM ',
      ),
    );

    expect(result.isRight(), isTrue);
  });
}
