import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/wallets/domain/entities/wallet_entity.dart';
import 'package:fin_sight_ai/features/wallets/domain/services/wallet_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

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
  const bank = WalletEntity(
    id: 'bank',
    name: 'Bank',
    type: WalletType.bank,
    openingBalance: 100,
  );
  const cash = WalletEntity(
    id: 'cash',
    name: 'Cash',
    type: WalletType.cash,
    openingBalance: 50,
  );

  test('computes bank and cash balances from transactions and transfers', () {
    final balances = WalletCalculator.balances(
      wallets: const [bank, cash],
      transactions: [
        tx(amount: 200, type: TransactionType.income, walletId: 'bank'),
        tx(amount: 30, type: TransactionType.expense, walletId: 'cash'),
        tx(amount: 10, type: TransactionType.income),
      ],
      transfers: [
        WalletTransferEntity(
          id: 't-1',
          fromWalletId: 'bank',
          toWalletId: 'cash',
          amount: 40,
          date: DateTime.utc(2026, 10, 2),
        ),
      ],
    );

    expect(balances.firstWhere((b) => b.wallet.id == 'bank').balance, 270);
    expect(balances.firstWhere((b) => b.wallet.id == 'cash').balance, 60);
  });

  test('ignores transfers with unknown wallets', () {
    final balances = WalletCalculator.balances(
      wallets: const [bank, cash],
      transactions: const [],
      transfers: [
        WalletTransferEntity(
          id: 't-1',
          fromWalletId: 'unknown',
          toWalletId: 'cash',
          amount: 40,
          date: DateTime.utc(2026, 10, 2),
        ),
      ],
    );

    expect(balances.firstWhere((b) => b.wallet.id == 'cash').balance, 50);
  });

  test('returns an empty list without wallets', () {
    expect(
      WalletCalculator.balances(
        wallets: const [],
        transactions: const [],
        transfers: const [],
      ),
      isEmpty,
    );
  });
}
