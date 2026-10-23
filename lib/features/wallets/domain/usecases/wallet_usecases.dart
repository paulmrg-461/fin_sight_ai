import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

@lazySingleton
class GetWalletBalancesUseCase
    implements UseCase<List<WalletBalance>, NoParams> {
  const GetWalletBalancesUseCase(this._repository);

  final WalletRepository _repository;

  @override
  ResultFuture<List<WalletBalance>> call(NoParams params) =>
      _repository.getWalletBalances();
}

class SetWalletBalanceParams {
  const SetWalletBalanceParams({required this.walletId, required this.target});

  final String walletId;
  final double target;
}

@lazySingleton
class SetWalletBalanceUseCase
    implements UseCase<WalletBalance, SetWalletBalanceParams> {
  const SetWalletBalanceUseCase(this._repository);

  final WalletRepository _repository;

  @override
  Future<Result<WalletBalance>> call(SetWalletBalanceParams params) async {
    if (params.walletId.trim().isEmpty) {
      return const Left(
        ValidationFailure('Wallet id is required.', code: 'missing_wallet'),
      );
    }
    if (!params.target.isFinite || params.target < 0) {
      return const Left(
        ValidationFailure(
          'Balance cannot be negative.',
          code: 'invalid_balance',
        ),
      );
    }
    return _repository.setWalletBalance(
      walletId: params.walletId,
      target: double.parse(params.target.toStringAsFixed(2)),
    );
  }
}

class TransferBetweenWalletsParams {
  const TransferBetweenWalletsParams({
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.date,
    this.note = '',
  });

  final String fromWalletId;
  final String toWalletId;
  final double amount;
  final DateTime date;
  final String note;
}

@lazySingleton
class TransferBetweenWalletsUseCase
    implements UseCase<WalletTransferEntity, TransferBetweenWalletsParams> {
  TransferBetweenWalletsUseCase(this._repository, {this.uuid = const Uuid()});

  final WalletRepository _repository;
  final Uuid uuid;

  @override
  Future<Result<WalletTransferEntity>> call(
    TransferBetweenWalletsParams params,
  ) async {
    if (params.fromWalletId.trim().isEmpty ||
        params.toWalletId.trim().isEmpty) {
      return const Left(
        ValidationFailure('Choose both wallets.', code: 'missing_wallet'),
      );
    }
    if (params.fromWalletId == params.toWalletId) {
      return const Left(
        ValidationFailure('Choose two different wallets.', code: 'same_wallet'),
      );
    }
    if (!params.amount.isFinite || params.amount <= 0) {
      return const Left(
        ValidationFailure(
          'Transfer amount must be greater than zero.',
          code: 'invalid_amount',
        ),
      );
    }

    return _repository.transfer(
      fromWalletId: params.fromWalletId,
      toWalletId: params.toWalletId,
      amount: double.parse(params.amount.toStringAsFixed(2)),
      date: params.date,
      note: params.note.trim(),
    );
  }
}
