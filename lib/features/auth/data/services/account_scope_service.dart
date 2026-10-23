import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/services/local_data_scope.dart';
import '../../../../core/usecase/usecase.dart';
import '../datasources/session_storage.dart';

/// Verifies that the local data belongs to the stored session's account.
///
/// Runs once at startup, before any feature bloc reads local storage. Returns
/// `true` when a mismatch was found and the local data was erased.
@lazySingleton
class AccountScopeService {
  const AccountScopeService(this._storage, this._localDataScope);

  final SessionStorage _storage;
  final LocalDataScope _localDataScope;

  Future<Result<bool>> ensure() async {
    try {
      final session = await _storage.read();
      if (session == null) {
        return const Right(false);
      }

      final owner = await _localDataScope.getOwnerUserId();
      if (owner == session.userId) {
        return const Right(false);
      }

      if (owner == null) {
        await _localDataScope.setOwnerUserId(session.userId);
        return const Right(false);
      }

      await _localDataScope.clearAllUserData();
      await _localDataScope.setOwnerUserId(session.userId);
      return const Right(true);
    } catch (_) {
      return const Left(
        CacheFailure(
          'Could not verify which account owns this device.',
          code: 'local_scope_failed',
        ),
      );
    }
  }
}
