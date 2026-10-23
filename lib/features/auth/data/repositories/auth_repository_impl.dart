import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/local_data_scope.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/session_storage.dart';

/// Persists sessions, refreshes expired tokens, and maps auth errors.
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._remoteDataSource,
    this._storage,
    this._localDataScope, {
    this.clock = const Clock(),
  });

  final AuthRemoteDataSource _remoteDataSource;
  final SessionStorage _storage;
  final LocalDataScope _localDataScope;
  final Clock clock;

  AuthSession? _session;

  /// Refresh failures that mean "try again later", not "you are signed out".
  static const Set<String> _transientRefreshCodes = <String>{
    'auth_timeout',
    'auth_network_error',
    'auth_not_configured',
    'auth_http_429',
  };

  /// Whether a failed refresh should keep the stored session.
  ///
  /// Timeouts, connectivity errors, missing configuration, rate limiting, and
  /// 5xx responses are transient. Anything else (400/401/403, invalid payload)
  /// is a permanent rejection and clears only the stored session.
  static bool _isTransientRefreshFailure(String? code) {
    if (code == null) {
      return false;
    }
    return _transientRefreshCodes.contains(code) ||
        code.startsWith('auth_http_5');
  }

  @override
  String? get accessToken => isAuthenticated ? _session?.accessToken : null;

  @override
  bool get isAuthenticated =>
      _session != null && _session!.expiresAt.isAfter(clock.now());

  @override
  ResultFuture<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _remoteDataSource.signIn(
        email: email,
        password: password,
      );
      await _storage.write(session);
      await _localDataScope.setOwnerUserId(session.userId);
      _session = session;
      return Right(session);
    } on AuthException catch (exception) {
      return Left(_authFailure(exception));
    } on CacheException catch (exception) {
      return Left(_storageFailure(exception));
    } catch (_) {
      return const Left(
        AuthFailure('Authentication failed.', code: 'auth_failed'),
      );
    }
  }

  @override
  ResultFuture<AuthSession> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final session = await _remoteDataSource.signUp(
        email: email,
        password: password,
      );
      await _storage.write(session);
      await _localDataScope.setOwnerUserId(session.userId);
      _session = session;
      return Right(session);
    } on AuthException catch (exception) {
      return Left(_authFailure(exception));
    } on CacheException catch (exception) {
      return Left(_storageFailure(exception));
    } catch (_) {
      return const Left(
        AuthFailure(
          'Could not create the account.',
          code: 'auth_signup_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<AuthSession?> restoreSession() async {
    try {
      final stored = await _storage.read();
      if (stored == null) {
        _session = null;
        return const Right(null);
      }

      if (stored.expiresAt.isAfter(clock.now())) {
        _session = stored;
        return Right(stored);
      }

      try {
        final refreshed = await _remoteDataSource.refresh(stored.refreshToken);
        await _storage.write(refreshed);
        await _localDataScope.setOwnerUserId(refreshed.userId);
        _session = refreshed;
        return Right(refreshed);
      } on AuthException catch (exception) {
        if (_isTransientRefreshFailure(exception.code)) {
          // Opening offline must stay signed in: keep the stored session and
          // the local ledger untouched until a later refresh succeeds.
          _session = stored;
          return Right(stored);
        }

        // The server rejected the refresh token for good. Only the session is
        // erased; the local ledger and owner stay so a later login reclaims
        // them. Erasing local data stays reserved for explicit sign-out.
        await _storage.clear();
        _session = null;
        return const Right(null);
      }
    } on AuthException catch (exception) {
      return Left(_authFailure(exception));
    } catch (_) {
      return const Left(
        AuthFailure(
          'Could not restore the session.',
          code: 'auth_restore_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<void> signOut() async {
    final token = _session?.accessToken;
    try {
      if (token != null) {
        await _remoteDataSource.signOut(token);
      }
    } catch (_) {
      // Signing out locally is authoritative even if the network fails.
    }

    try {
      await _storage.clear();
      _session = null;
    } catch (_) {
      return const Left(
        AuthFailure(
          'Could not clear the stored session.',
          code: 'auth_storage_failed',
        ),
      );
    }

    try {
      await _localDataScope.clearAllUserData();
      await _localDataScope.setOwnerUserId(null);
    } catch (_) {
      return const Left(
        CacheFailure('Could not clear local data.', code: 'local_clear_failed'),
      );
    }

    return const Right(null);
  }

  AuthFailure _authFailure(AuthException exception) =>
      AuthFailure(exception.message, code: exception.code);

  AuthFailure _storageFailure(CacheException exception) =>
      AuthFailure(exception.message, code: exception.code);
}
