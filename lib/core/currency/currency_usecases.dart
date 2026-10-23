import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../domain/failure.dart';
import '../usecase/usecase.dart';
import 'app_currency.dart';
import 'currency_repository.dart';

@lazySingleton
class GetCurrencyUseCase implements UseCase<AppCurrency, NoParams> {
  const GetCurrencyUseCase(this._repository);

  final CurrencyRepository _repository;

  @override
  Future<Result<AppCurrency>> call(NoParams params) async {
    try {
      return Right(await _repository.getCurrency());
    } catch (_) {
      return const Right(AppCurrency.cop);
    }
  }
}

@lazySingleton
class SetCurrencyUseCase implements UseCase<AppCurrency, AppCurrency> {
  const SetCurrencyUseCase(this._repository);

  final CurrencyRepository _repository;

  @override
  Future<Result<AppCurrency>> call(AppCurrency currency) async {
    try {
      await _repository.setCurrency(currency);
      return Right(currency);
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to save the currency preference.',
          code: 'currency_write_failed',
        ),
      );
    }
  }
}
