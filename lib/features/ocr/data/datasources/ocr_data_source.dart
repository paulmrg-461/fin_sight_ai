/// Contract for the platform OCR engine.
abstract interface class OcrDataSource {
  /// Returns the raw text recognized in [imagePath].
  ///
  /// Implementations throw `OcrException` when the engine is unavailable or
  /// fails to process the image.
  Future<String> recognizeText(String imagePath);
}
