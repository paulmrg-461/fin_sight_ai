import 'package:fpdart/fpdart.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../domain/failure.dart';
import '../usecase/usecase.dart';
import 'locale_repository.dart';

@lazySingleton
class GetLocaleUseCase implements UseCase<Locale?, NoParams> {
  const GetLocaleUseCase(this._repository);

  final LocaleRepository _repository;

  @override
  Future<Result<Locale?>> call(NoParams params) async {
    try {
      return Right(await _repository.getLocale());
    } catch (_) {
      return const Right(null);
    }
  }
}

@lazySingleton
class SetLocaleUseCase implements UseCase<Locale?, Locale?> {
  const SetLocaleUseCase(this._repository);

  final LocaleRepository _repository;

  @override
  Future<Result<Locale?>> call(Locale? locale) async {
    try {
      await _repository.setLocale(locale);
      return Right(locale);
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to save the language preference.',
          code: 'locale_write_failed',
        ),
      );
    }
  }
}
