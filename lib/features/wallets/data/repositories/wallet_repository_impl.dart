import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/clock.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/services/wallet_calculator.dart';
import '../datasources/wallet_local_data_source.dart';
import '../models/wallet_model.dart';

@LazySingleton(as: WalletRepository)
class WalletRepositoryImpl implements WalletRepository {
  WalletRepositoryImpl(
    this._localDataSource,
    this._transactionRepository, {
    this.uuid = const Uuid(),
    this.clock = const Clock(),
  });

  static const String bankWalletId = 'wallet-bank';
  static const String cashWalletId = 'wallet-cash';

  final WalletLocalDataSource _localDataSource;
  final TransactionRepository _transactionRepository;
  final Uuid uuid;
  final Clock clock;

  @override
  ResultFuture<List<WalletBalance>> getWalletBalances() async {
    try {
      final wallets = await _ensureDefaultWallets();
      final transactionsResult = await _transactionRepository.getTransactions();
      final failure = transactionsResult.getLeft().toNullable();
      if (failure != null) {
        return Left(failure);
      }

      final transfers = await _localDataSource.getTransfers();
      return Right(
        WalletCalculator.balances(
          wallets: wallets,
          transactions: transactionsResult.getOrElse(
            (_) => const <TransactionEntity>[],
          ),
          transfers: transfers.map((transfer) => transfer.toEntity()).toList(),
        ),
      );
    } on CacheException catch (exception) {
      return Left(_cacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to calculate wallet balances.',
          code: 'wallet_balance_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<WalletBalance> setWalletBalance({
    required String walletId,
    required double target,
  }) async {
    try {
      final wallets = await _ensureDefaultWallets();
      final wallet = _findWallet(wallets, walletId);
      if (wallet == null) {
        return const Left(
          ValidationFailure('Wallet not found.', code: 'wallet_not_found'),
        );
      }

      final balances = await getWalletBalances();
      final balancesFailure = balances.getLeft().toNullable();
      if (balancesFailure != null) {
        return Left(balancesFailure);
      }
      final current = balances
          .getOrElse((_) => const <WalletBalance>[])
          .firstWhere(
            (balance) => balance.wallet.id == walletId,
            orElse: () => WalletBalance(wallet: wallet, balance: 0),
          )
          .balance;

      final delta = target - current;
      final updated = wallet.copyWith(
        openingBalance: _round(wallet.openingBalance + delta),
        updatedAt: clock.now(),
      );
      await _localDataSource.saveWallet(WalletModel.fromEntity(updated));

      return Right(WalletBalance(wallet: updated, balance: target));
    } on CacheException catch (exception) {
      return Left(_cacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to update the wallet balance.',
          code: 'wallet_update_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<WalletTransferEntity> transfer({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    required DateTime date,
    String note = '',
  }) async {
    try {
      final wallets = await _ensureDefaultWallets();
      final from = _findWallet(wallets, fromWalletId);
      final to = _findWallet(wallets, toWalletId);
      if (from == null || to == null) {
        return const Left(
          ValidationFailure('Wallet not found.', code: 'wallet_not_found'),
        );
      }
      if (from.id == to.id) {
        return const Left(
          ValidationFailure(
            'Choose two different wallets.',
            code: 'same_wallet',
          ),
        );
      }

      final balances = await getWalletBalances();
      final balancesFailure = balances.getLeft().toNullable();
      if (balancesFailure != null) {
        return Left(balancesFailure);
      }
      final fromBalance = balances
          .getOrElse((_) => const <WalletBalance>[])
          .firstWhere(
            (balance) => balance.wallet.id == fromWalletId,
            orElse: () => WalletBalance(wallet: from, balance: 0),
          )
          .balance;
      if (amount > fromBalance + 0.004) {
        return const Left(
          ValidationFailure(
            'Insufficient funds in the source wallet.',
            code: 'insufficient_funds',
          ),
        );
      }

      final transfer = WalletTransferEntity(
        id: uuid.v4(),
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        amount: _round(amount),
        date: date,
        note: note,
        createdAt: clock.now(),
      );
      await _localDataSource.saveTransfer(
        WalletTransferModel.fromEntity(transfer),
      );
      return Right(transfer);
    } on CacheException catch (exception) {
      return Left(_cacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure('Unable to transfer money.', code: 'transfer_failed'),
      );
    }
  }

  Future<List<WalletEntity>> _ensureDefaultWallets() async {
    final existing = await _localDataSource.getWallets();
    final wallets = existing.map((wallet) => wallet.toEntity()).toList();

    if (!wallets.any((wallet) => wallet.type == WalletType.bank)) {
      final bank = WalletModel(
        id: bankWalletId,
        name: 'Cuenta principal',
        type: WalletType.bank,
        openingBalance: 0,
        updatedAt: clock.now(),
      );
      await _localDataSource.saveWallet(bank);
      wallets.add(bank.toEntity());
    }
    if (!wallets.any((wallet) => wallet.type == WalletType.cash)) {
      final cash = WalletModel(
        id: cashWalletId,
        name: 'Efectivo',
        type: WalletType.cash,
        openingBalance: 0,
        updatedAt: clock.now(),
      );
      await _localDataSource.saveWallet(cash);
      wallets.add(cash.toEntity());
    }

    wallets.sort((a, b) => a.type.index.compareTo(b.type.index));
    return wallets;
  }

  WalletEntity? _findWallet(List<WalletEntity> wallets, String id) {
    for (final wallet in wallets) {
      if (wallet.id == id) {
        return wallet;
      }
    }
    return null;
  }

  double _round(double value) => double.parse(value.toStringAsFixed(2));

  CacheFailure _cacheFailure(CacheException exception) =>
      CacheFailure(exception.message, code: exception.code);
}
