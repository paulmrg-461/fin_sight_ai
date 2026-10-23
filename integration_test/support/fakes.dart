import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/services/receipt_image_picker.dart';
import 'package:fin_sight_ai/features/ai_coach/data/datasources/ai_coach_datasource.dart';
import 'package:fin_sight_ai/features/ocr/data/datasources/ocr_data_source.dart';

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
