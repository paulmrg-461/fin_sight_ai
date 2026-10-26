import 'package:fin_sight_ai/features/wallets/domain/entities/wallet_entity.dart';
import 'package:flutter_test/flutter_test.dart';

final deletedAtForTest = DateTime.utc(2026, 10, 4);

void main() {
  const bank = WalletEntity(
    id: 'bank',
    name: 'Cuenta',
    type: WalletType.bank,
    openingBalance: 100,
  );

  test('WalletEntity supports copyWith, equality, and toString', () {
    final updated = bank.copyWith(name: 'Ahorros', openingBalance: 250);

    expect(updated.name, 'Ahorros');
    expect(updated.openingBalance, 250);
    expect(updated.id, bank.id);
    expect(bank, isNot(updated));
    expect(
      bank,
      const WalletEntity(
        id: 'bank',
        name: 'Cuenta',
        type: WalletType.bank,
        openingBalance: 100,
      ),
    );
    expect(bank.toString(), contains('Cuenta'));
  });

  test('WalletEntity tracks sync metadata and tombstones', () {
    final updatedAt = DateTime.utc(2026, 10, 20);
    final deletedAt = DateTime.utc(2026, 10, 21);
    final synced = bank.copyWith(
      updatedAt: updatedAt,
      isSynced: true,
      deletedAt: deletedAt,
      currency: 'COP',
      type: WalletType.cash,
      id: 'cash',
    );

    expect(synced.id, 'cash');
    expect(synced.type, WalletType.cash);
    expect(synced.currency, 'COP');
    expect(synced.isSynced, isTrue);
    expect(synced.isDeleted, isTrue);
    expect(synced.deletedAt, deletedAt);
    expect(synced.lastModified, updatedAt);
    expect(synced, isNot(bank));
    expect(synced.hashCode, isNot(bank.hashCode));
    expect(
      bank.lastModified,
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  });

  test('WalletTransferEntity supports equality and toString', () {
    final date = DateTime.utc(2026, 10, 2);
    final transfer = WalletTransferEntity(
      id: 't-1',
      fromWalletId: 'bank',
      toWalletId: 'cash',
      amount: 40,
      date: date,
    );

    expect(
      transfer,
      WalletTransferEntity(
        id: 't-1',
        fromWalletId: 'bank',
        toWalletId: 'cash',
        amount: 40,
        date: date,
      ),
    );
    expect(transfer.toString(), contains('40.0'));
    expect(transfer, isNot(transfer.copyWithAmount(50)));
    expect(transfer.lastModified, date);
    expect(transfer.hashCode, isNonZero);
    expect(transfer.isDeleted, isFalse);
    expect(transfer.isSynced, isFalse);
  });

  test('WalletTransferEntity tracks sync metadata', () {
    final date = DateTime.utc(2026, 10, 2);
    final createdAt = DateTime.utc(2026, 10, 2);
    final updatedAt = DateTime.utc(2026, 10, 3);
    final transfer =
        WalletTransferEntity(
          id: 't-1',
          fromWalletId: 'bank',
          toWalletId: 'cash',
          amount: 40,
          date: date,
          createdAt: createdAt,
        ).copyWith(
          updatedAt: updatedAt,
          isSynced: true,
          deletedAt: deletedAtForTest,
          note: 'ATM',
          amount: 55,
        );

    expect(transfer.amount, 55);
    expect(transfer.note, 'ATM');
    expect(transfer.isSynced, isTrue);
    expect(transfer.isDeleted, isTrue);
    expect(transfer.lastModified, updatedAt);
  });

  test('WalletBalance exposes the wallet and balance', () {
    final balance = WalletBalance(wallet: bank, balance: 100);

    expect(balance.name, 'Cuenta');
    expect(balance.type, WalletType.bank);
    expect(balance, WalletBalance(wallet: bank, balance: 100));
    expect(balance, isNot(const WalletBalance(wallet: bank, balance: 1)));
    expect(balance.hashCode, isNonZero);
    expect(balance.toString(), contains('100.0'));
  });
}

extension on WalletTransferEntity {
  WalletTransferEntity copyWithAmount(double amount) => WalletTransferEntity(
    id: id,
    fromWalletId: fromWalletId,
    toWalletId: toWalletId,
    amount: amount,
    date: date,
    note: note,
    createdAt: createdAt,
  );
}
