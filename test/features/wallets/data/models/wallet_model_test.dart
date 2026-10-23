import 'dart:convert';

import 'package:fin_sight_ai/features/wallets/data/models/wallet_model.dart';
import 'package:fin_sight_ai/features/wallets/domain/entities/wallet_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips a wallet', () {
    const model = WalletModel(
      id: 'wallet-bank',
      name: 'Cuenta principal',
      type: WalletType.bank,
      openingBalance: 100,
    );

    final decoded = jsonDecode(jsonEncode(model.toJson()));
    final restored = WalletModel.fromJson(decoded as Map<String, dynamic>);

    expect(restored.toEntity(), model.toEntity());
  });

  test('round-trips a transfer', () {
    final transfer = WalletTransferModel(
      id: 't-1',
      fromWalletId: 'bank',
      toWalletId: 'cash',
      amount: 40,
      date: DateTime.utc(2026, 10, 2),
      note: 'ATM',
    );

    final decoded = jsonDecode(jsonEncode(transfer.toJson()));
    final restored = WalletTransferModel.fromJson(
      decoded as Map<String, dynamic>,
    );

    expect(restored.toEntity(), transfer.toEntity());
  });

  test('rejects invalid wallets and transfers', () {
    expect(() => WalletModel.fromJson(const {'id': ''}), throwsFormatException);
    expect(
      () => WalletModel.fromJson(const {
        'id': 'w',
        'name': 'Bank',
        'type': 'crypto',
        'openingBalance': 0,
      }),
      throwsFormatException,
    );
    expect(
      () => WalletTransferModel.fromJson(const {'id': 't'}),
      throwsFormatException,
    );
  });
}
