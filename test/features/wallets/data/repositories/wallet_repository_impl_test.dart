import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fin_sight_ai/features/wallets/data/datasources/wallet_local_data_source.dart';
import 'package:fin_sight_ai/features/wallets/data/models/wallet_model.dart';
import 'package:fin_sight_ai/features/wallets/data/repositories/wallet_repository_impl.dart';
import 'package:fin_sight_ai/features/wallets/domain/entities/wallet_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockWalletLocalDataSource extends Mock implements WalletLocalDataSource {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

WalletModel bankModel({double opening = 0}) => WalletModel(
  id: 'wallet-bank',
  name: 'Cuenta principal',
  type: WalletType.bank,
  openingBalance: opening,
);

WalletModel cashModel({double opening = 0}) => WalletModel(
  id: 'wallet-cash',
  name: 'Efectivo',
  type: WalletType.cash,
  openingBalance: opening,
);

TransactionEntity tx({
  required double amount,
  required TransactionType type,
  String? walletId,
}) => TransactionEntity(
  id: 'tx-${amount}_${type.name}_$walletId',
  amount: amount,
  type: type,
  category: 'General',
  description: '',
  date: DateTime.utc(2026, 10, 1),
  walletId: walletId,
);

void main() {
  late MockWalletLocalDataSource local;
  late MockTransactionRepository transactions;
  late WalletRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(bankModel());
    registerFallbackValue(
      WalletTransferModel(
        id: 'fallback',
        fromWalletId: 'bank',
        toWalletId: 'cash',
        amount: 1,
        date: DateTime.utc(2026),
      ),
    );
  });

  setUp(() {
    local = MockWalletLocalDataSource();
    transactions = MockTransactionRepository();
    repository = WalletRepositoryImpl(local, transactions);
    when(() => local.saveWallet(any())).thenAnswer((_) async {});
    when(() => local.saveTransfer(any())).thenAnswer((_) async {});
    when(() => local.getTransfers()).thenAnswer((_) async => []);
    when(() => transactions.getTransactions())
        .thenAnswer((_) async => const Right([]));
  });

  test('creates default bank and cash wallets when empty', () async {
    when(() => local.getWallets()).thenAnswer((_) async => []);

    final result = await repository.getWalletBalances();

    final balances = result.getOrElse((_) => fail('Expected balances'));
    expect(balances, hasLength(2));
    expect(balances.first.wallet.type, WalletType.bank);
    expect(balances.last.wallet.type, WalletType.cash);
    verify(() => local.saveWallet(any())).called(2);
  });

  test('aggregates transactions and transfers', () async {
    when(() => local.getWallets()).thenAnswer(
      (_) async => [bankModel(opening: 100), cashModel(opening: 50)],
    );
    when(() => transactions.getTransactions()).thenAnswer(
      (_) async => Right([
        tx(amount: 200, type: TransactionType.income, walletId: 'wallet-bank'),
        tx(amount: 30, type: TransactionType.expense, walletId: 'wallet-cash'),
      ]),
    );
    when(() => local.getTransfers()).thenAnswer(
      (_) async => [
        WalletTransferModel(
          id: 't-1',
          fromWalletId: 'wallet-bank',
          toWalletId: 'wallet-cash',
          amount: 40,
          date: DateTime.utc(2026, 10, 2),
        ),
      ],
    );

    final result = await repository.getWalletBalances();

    final balances = result.getOrElse((_) => fail('Expected balances'));
    expect(
      balances.firstWhere((b) => b.wallet.id == 'wallet-bank').balance,
      260,
    );
    expect(
      balances.firstWhere((b) => b.wallet.id == 'wallet-cash').balance,
      60,
    );
  });

  test('reconciles a balance by adjusting the opening balance', () async {
    when(() => local.getWallets()).thenAnswer((_) async => [bankModel()]);
    when(() => transactions.getTransactions()).thenAnswer(
      (_) async => Right([
        tx(amount: 100, type: TransactionType.income, walletId: 'wallet-bank'),
      ]),
    );

    final result = await repository.setWalletBalance(
      walletId: 'wallet-bank',
      target: 500,
    );

    final balance = result.getOrElse((_) => fail('Expected balance'));
    expect(balance.balance, 500);
    final saved = verify(() => local.saveWallet(captureAny())).captured
        .cast<WalletModel>()
        .firstWhere((wallet) => wallet.id == 'wallet-bank');
    expect(saved.openingBalance, 400);
  });

  test('transfers money between bank and cash', () async {
    when(() => local.getWallets())
        .thenAnswer((_) async => [bankModel(opening: 100), cashModel()]);

    final result = await repository.transfer(
      fromWalletId: 'wallet-bank',
      toWalletId: 'wallet-cash',
      amount: 40,
      date: DateTime.utc(2026, 10, 2),
    );

    final transfer = result.getOrElse((_) => fail('Expected transfer'));
    expect(transfer.amount, 40);
    verify(() => local.saveTransfer(any())).called(1);
  });

  test('rejects transfers above the source balance', () async {
    when(() => local.getWallets())
        .thenAnswer((_) async => [bankModel(opening: 100), cashModel()]);

    final result = await repository.transfer(
      fromWalletId: 'wallet-bank',
      toWalletId: 'wallet-cash',
      amount: 200,
      date: DateTime.utc(2026, 10, 2),
    );

    expect(result.getLeft().toNullable()?.code, 'insufficient_funds');
    verifyNever(() => local.saveTransfer(any()));
  });

  test('maps cache failures', () async {
    when(
      () => local.getWallets(),
    ).thenThrow(const CacheException('Corrupt.', code: 'wallet_read_failed'));

    final result = await repository.getWalletBalances();

    expect(result.getLeft().toNullable(), isA<CacheFailure>());
  });
}
