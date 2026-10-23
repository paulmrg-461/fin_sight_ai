import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import 'ocr_data_source.dart';

/// Google ML Kit implementation of [OcrDataSource].
///
/// ML Kit is available on Android and iOS. Other platforms surface an
/// `OcrException`, which the repository maps to a user-facing failure.
@LazySingleton(as: OcrDataSource)
class MlKitOcrDataSource implements OcrDataSource {
  const MlKitOcrDataSource();

  @override
  Future<String> recognizeText(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await recognizer.processImage(inputImage);
      return recognizedText.text;
    } on PlatformException catch (exception) {
      throw OcrException(
        'The OCR engine is unavailable on this device.',
        code: exception.code,
      );
    } catch (_) {
      throw const OcrException(
        'Unable to read the receipt image.',
        code: 'ocr_failed',
      );
    } finally {
      try {
        await recognizer.close();
      } catch (_) {
        // Releasing native resources must not mask the recognition result.
      }
    }
  }
}
