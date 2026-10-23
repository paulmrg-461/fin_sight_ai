import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../error/exceptions.dart';

/// Copies picked receipt images into app-owned storage.
abstract interface class ReceiptImageStore {
  /// Copies [sourcePath] into persistent storage and returns the new path.
  Future<String> persist(String sourcePath);

  /// Best-effort deletion of a persisted image.
  Future<void> delete(String path);
}

/// File-backed implementation under `<documents>/receipts`.
@LazySingleton(as: ReceiptImageStore)
class FileReceiptImageStore implements ReceiptImageStore {
  FileReceiptImageStore() : _directory = null;

  /// Test seam: persist into an explicit directory.
  FileReceiptImageStore.withDirectory(Directory directory)
    : _directory = directory;

  final Directory? _directory;

  @override
  Future<String> persist(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const CacheException(
        'The receipt image no longer exists.',
        code: 'receipt_image_missing',
      );
    }

    final directory = await _resolveDirectory();
    await directory.create(recursive: true);

    final extension = p.extension(sourcePath);
    final fileName =
        'receipt_${DateTime.now().microsecondsSinceEpoch}$extension';
    final destination = File(p.join(directory.path, fileName));
    await source.copy(destination.path);
    return destination.path;
  }

  @override
  Future<void> delete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Cleanup is best effort; never block the scan flow.
    }
  }

  Future<Directory> _resolveDirectory() async {
    final existing = _directory;
    if (existing != null) {
      return existing;
    }
    final documents = await getApplicationDocumentsDirectory();
    return Directory(p.join(documents.path, 'receipts'));
  }
}
