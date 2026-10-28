import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/services/biometric_service.dart';
import 'package:fin_sight_ai/core/services/onboarding_service.dart';
import 'package:fin_sight_ai/core/services/security_preferences.dart';
import 'package:fin_sight_ai/core/services/receipt_image_picker.dart';
import 'package:fin_sight_ai/features/ai_coach/data/datasources/ai_coach_datasource.dart';
import 'package:fin_sight_ai/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fin_sight_ai/features/auth/data/datasources/session_storage.dart';
import 'package:fin_sight_ai/features/auth/domain/entities/auth_session.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fin_sight_ai/features/ocr/data/datasources/ocr_data_source.dart';
import 'package:fin_sight_ai/features/reports/domain/repositories/report_exporter.dart';

/// Deterministic OCR result used by integration tests.
class FakeOcrDataSource implements OcrDataSource {
  bool shouldFail = false;

  String text = '''
ACME MARKET
Milk 2 x 3.50
Bread 4.50
TOTAL \$25.50
''';

  @override
  Future<String> recognizeText(String imagePath) async {
    if (shouldFail) {
      throw const OcrException('OCR unavailable.', code: 'ocr_unavailable');
    }
    return text;
  }
}

/// Deterministic Groq response used by integration tests.
class FakeGroqDatasource implements AiCoachDatasource {
  bool shouldFail = false;

  String response =
      '{"type":"suggestion",'
      '"content":"Automate 10% of your income.",'
      '"relatedTransactionId":null}';

  @override
  Future<String> callGroqApi(String prompt, String context) async {
    if (shouldFail) {
      throw const ServerException('Groq offline.', code: 'groq_network_error');
    }
    return response;
  }
}

/// Returns a stable path without touching camera or gallery plugins.
class FakeReceiptImagePicker implements ReceiptImagePicker {
  @override
  Future<String?> pick(ReceiptImageSource source) async =>
      '/tmp/fake-receipt.jpg';
}

/// In-memory session storage so integration tests can seed a stored session.
class InMemorySessionStorage implements SessionStorage {
  InMemorySessionStorage([this.session]);

  AuthSession? session;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> write(AuthSession session) async {
    this.session = session;
  }

  @override
  Future<void> clear() async {
    session = null;
  }
}

/// Deterministic Supabase Auth double: no network, rotating tokens, and a
/// switch that simulates an offline refresh.
class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  AuthSession? session;
  bool failRefresh = false;
  int refreshCount = 0;

  AuthSession _sessionFor(String email, String suffix) {
    return AuthSession(
      accessToken: 'access-$suffix',
      refreshToken: 'refresh-$suffix',
      userId: 'integration-user',
      email: email,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.length < 6) {
      throw const AuthException(
        'Invalid credentials.',
        code: 'auth_invalid_credentials',
      );
    }
    return session = _sessionFor(email.trim(), '1');
  }

  @override
  Future<AuthSession> signUp({
    required String email,
    required String password,
  }) => signIn(email: email, password: password);

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    refreshCount++;
    if (failRefresh) {
      throw const AuthException(
        'Could not reach Supabase Auth.',
        code: 'auth_network_error',
      );
    }

    final current = session;
    if (current == null) {
      throw const AuthException(
        'Refresh token rejected.',
        code: 'auth_http_401',
      );
    }

    return session = AuthSession(
      accessToken: 'refreshed-access-$refreshCount',
      refreshToken: 'refreshed-refresh-$refreshCount',
      userId: current.userId,
      email: current.email,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<void> signOut(String accessToken) async {}
}

/// Records report shares without invoking a platform share sheet.
class FakeReportExporter implements ReportExporter {
  bool shouldFail = false;
  String? lastCsv;
  String? lastFileName;

  @override
  ResultFuture<String> shareCsv({
    required String fileName,
    required String csv,
    required String subject,
  }) async {
    lastFileName = fileName;
    lastCsv = csv;
    if (shouldFail) {
      return const Left(
        CacheFailure(
          'Unable to share the report.',
          code: 'report_share_failed',
        ),
      );
    }
    return Right('/tmp/$fileName');
  }
}

/// In-memory first-run flag for integration tests.
class FakeOnboardingService implements OnboardingService {
  FakeOnboardingService({this.completed = true});

  bool completed;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> complete() async {
    completed = true;
  }
}

class FakeBiometricService implements BiometricService {
  FakeBiometricService({this.available = true, this.result = true});

  bool available;
  bool result;
  int authenticateCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate() async {
    authenticateCalls++;
    return result;
  }
}

class FakeSecurityPreferences implements SecurityPreferences {
  FakeSecurityPreferences({this.enabled = false});

  bool enabled;

  @override
  Future<bool> isBiometricEnabled() async => enabled;

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    this.enabled = enabled;
  }
}
