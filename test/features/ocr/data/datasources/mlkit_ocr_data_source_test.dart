import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/features/ocr/data/datasources/mlkit_ocr_data_source.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('google_mlkit_text_recognizer');
  const dataSource = MlKitOcrDataSource();

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void mockHandler(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  test('returns recognized text and closes the recognizer', () async {
    final methods = <String>[];
    mockHandler((call) async {
      methods.add(call.method);
      if (call.method == 'vision#startTextRecognizer') {
        return {'text': 'ACME MARKET', 'blocks': <dynamic>[]};
      }
      return null;
    });

    final text = await dataSource.recognizeText('/tmp/receipt.jpg');

    expect(text, 'ACME MARKET');
    expect(methods, contains('vision#closeTextRecognizer'));
  });

  test('maps platform errors to OcrException', () async {
    mockHandler((call) async {
      if (call.method == 'vision#startTextRecognizer') {
        throw PlatformException(code: 'ocr_unavailable');
      }
      return null;
    });

    await expectLater(
      dataSource.recognizeText('/tmp/receipt.jpg'),
      throwsA(
        isA<OcrException>().having((e) => e.code, 'code', 'ocr_unavailable'),
      ),
    );
  });

  test('maps unexpected errors to a generic OcrException', () async {
    mockHandler((call) async {
      if (call.method == 'vision#startTextRecognizer') {
        throw StateError('boom');
      }
      return null;
    });

    await expectLater(
      dataSource.recognizeText('/tmp/receipt.jpg'),
      throwsA(isA<OcrException>()),
    );
  });
}
