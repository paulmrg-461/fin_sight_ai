import 'package:fin_sight_ai/core/services/receipt_image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  late MockImagePicker picker;
  late ImagePickerReceiptImagePicker imagePicker;

  setUpAll(() {
    registerFallbackValue(ImageSource.gallery);
  });

  setUp(() {
    picker = MockImagePicker();
    imagePicker = ImagePickerReceiptImagePicker.withPicker(picker);
  });

  test('returns the picked file path for the camera', () async {
    when(
      () => picker.pickImage(
        source: any(named: 'source'),
        imageQuality: any(named: 'imageQuality'),
      ),
    ).thenAnswer((_) async => XFile('/tmp/receipt.jpg'));

    final path = await imagePicker.pick(ReceiptImageSource.camera);

    expect(path, '/tmp/receipt.jpg');
    verify(() => picker.pickImage(source: ImageSource.camera, imageQuality: 90))
        .called(1);
  });

  test('returns the gallery path', () async {
    when(
      () => picker.pickImage(
        source: any(named: 'source'),
        imageQuality: any(named: 'imageQuality'),
      ),
    ).thenAnswer((_) async => XFile('/tmp/gallery.jpg'));

    final path = await imagePicker.pick(ReceiptImageSource.gallery);

    expect(path, '/tmp/gallery.jpg');
  });

  test('returns null when the user cancels', () async {
    when(
      () => picker.pickImage(
        source: any(named: 'source'),
        imageQuality: any(named: 'imageQuality'),
      ),
    ).thenAnswer((_) async => null);

    expect(await imagePicker.pick(ReceiptImageSource.camera), isNull);
  });

  test('returns null when the platform rejects the request', () async {
    when(
      () => picker.pickImage(
        source: any(named: 'source'),
        imageQuality: any(named: 'imageQuality'),
      ),
    ).thenThrow(PlatformException(code: 'camera_access_denied'));

    expect(await imagePicker.pick(ReceiptImageSource.camera), isNull);
  });
}
