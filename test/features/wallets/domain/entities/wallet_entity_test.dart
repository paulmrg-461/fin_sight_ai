import 'package:fin_sight_ai/features/wallets/domain/entities/wallet_entity.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });

  test('WalletBalance exposes the wallet and balance', () {
    final balance = WalletBalance(wallet: bank, balance: 100);

    expect(balance.name, 'Cuenta');
    expect(balance.type, WalletType.bank);
    expect(balance, WalletBalance(wallet: bank, balance: 100));
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
