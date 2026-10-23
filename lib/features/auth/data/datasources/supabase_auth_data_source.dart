import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/app_env.dart';
import '../../domain/entities/auth_session.dart';
import 'auth_remote_data_source.dart';

/// Supabase Auth implementation over GoTrue REST endpoints.
@LazySingleton(as: AuthRemoteDataSource)
class SupabaseAuthDataSource implements AuthRemoteDataSource {
  SupabaseAuthDataSource(this._client, this._env);

  static const Duration timeout = Duration(seconds: 15);

  final http.Client _client;
  final AppEnv _env;

  void _ensureConfigured() {
    if (!_env.hasSupabase) {
      throw const AuthException(
        'Supabase is not configured.',
        code: 'auth_not_configured',
      );
    }
  }

  Map<String, String> get _headers => <String, String>{
    'apikey': _env.supabaseAnonKey,
    'Content-Type': 'application/json',
  };

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    _ensureConfigured();
    final response = await _send(
      () => _client
          .post(
            _uri('token', {'grant_type': 'password'}),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(timeout),
    );

    if (response.statusCode == 400 || response.statusCode == 401) {
      throw const AuthException(
        'Invalid email or password.',
        code: 'auth_invalid_credentials',
      );
    }
    _ensureSuccess(response);
    return _parseSession(response.body);
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
  }) async {
    _ensureConfigured();
    final response = await _send(
      () => _client
          .post(
            _uri('signup'),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(timeout),
    );

    if (response.statusCode == 422) {
      throw const AuthException(
        'Could not create the account.',
        code: 'auth_signup_failed',
      );
    }
    _ensureSuccess(response);

    final decoded = _decode(response.body);
    if (decoded['access_token'] == null) {
      throw const AuthException(
        'Check your email to confirm the account.',
        code: 'auth_email_confirmation_required',
      );
    }
    return _parseSession(response.body);
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    _ensureConfigured();
    final response = await _send(
      () => _client
          .post(
            _uri('token', {'grant_type': 'refresh_token'}),
            headers: _headers,
            body: jsonEncode({'refresh_token': refreshToken}),
          )
          .timeout(timeout),
    );
    _ensureSuccess(response);
    return _parseSession(response.body);
  }

  @override
  Future<void> signOut(String accessToken) async {
    _ensureConfigured();
    final response = await _send(
      () => _client
          .post(
            _uri('logout'),
            headers: {..._headers, 'Authorization': 'Bearer $accessToken'},
          )
          .timeout(timeout),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw AuthException(
        'Sign out failed.',
        code: 'auth_http_${response.statusCode}',
      );
    }
  }

  AuthSession _parseSession(String body) {
    final decoded = _decode(body);
    final accessToken = decoded['access_token'];
    final refreshToken = decoded['refresh_token'];
    final user = decoded['user'];
    final expiresAt = decoded['expires_at'];
    final expiresIn = decoded['expires_in'];

    if (accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty ||
        user is! Map) {
      throw const AuthException(
        'Supabase returned an invalid session.',
        code: 'auth_invalid_response',
      );
    }

    final userId = user['id'];
    final email = user['email'];
    if (userId is! String || email is! String) {
      throw const AuthException(
        'Supabase returned an invalid user.',
        code: 'auth_invalid_response',
      );
    }

    DateTime expiry;
    if (expiresAt is int) {
      expiry = DateTime.fromMillisecondsSinceEpoch(
        expiresAt * 1000,
        isUtc: true,
      );
    } else if (expiresIn is int) {
      expiry = DateTime.now().toUtc().add(Duration(seconds: expiresIn));
    } else {
      expiry = DateTime.now().toUtc().add(const Duration(hours: 1));
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      email: email,
      expiresAt: expiry,
    );
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw const FormatException('Root is not an object.');
      }
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw const AuthException(
        'Supabase returned an invalid response.',
        code: 'auth_invalid_response',
      );
    }
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthException(
        'Authentication request failed.',
        code: 'auth_http_${response.statusCode}',
      );
    }
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on AuthException {
      rethrow;
    } on TimeoutException {
      throw const AuthException(
        'Authentication timed out.',
        code: 'auth_timeout',
      );
    } on http.ClientException {
      throw const AuthException(
        'Could not reach Supabase Auth.',
        code: 'auth_network_error',
      );
    } catch (_) {
      throw const AuthException(
        'Could not reach Supabase Auth.',
        code: 'auth_network_error',
      );
    }
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse('${_env.supabaseUrl}/auth/v1/$path')
        .replace(queryParameters: query);
  }
}
