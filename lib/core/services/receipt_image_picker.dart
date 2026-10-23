import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

/// Where the user wants to obtain a receipt image.
enum ReceiptImageSource { camera, gallery }

/// Picks a receipt image. Abstracted so presentation can be tested without
/// platform plugins.
abstract interface class ReceiptImagePicker {
  /// Returns the selected file path, or `null` when the user cancels.
  Future<String?> pick(ReceiptImageSource source);
}

/// `image_picker` implementation for Android, iOS, and desktop where supported.
@LazySingleton(as: ReceiptImagePicker)
class ImagePickerReceiptImagePicker implements ReceiptImagePicker {
  ImagePickerReceiptImagePicker() : _picker = ImagePicker();

  /// Test seam: inject a fake picker implementation.
  ImagePickerReceiptImagePicker.withPicker(this._picker);

  final ImagePicker _picker;

  @override
  Future<String?> pick(ReceiptImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == ReceiptImageSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 90,
      );
      return file?.path;
    } on PlatformException catch (_) {
      return null;
    }
  }
}
