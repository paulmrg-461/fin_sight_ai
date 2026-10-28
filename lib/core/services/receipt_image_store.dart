import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../error/exceptions.dart';
import 'hive_storage_location.dart' show DirectoryProvider;

/// Copies picked receipt images into app-owned storage.
abstract interface class ReceiptImageStore {
  /// Copies [sourcePath] into persistent storage and returns the new path.
  Future<String> persist(String sourcePath);

  /// Best-effort deletion of a persisted image.
  Future<void> delete(String path);

  /// Removes every persisted receipt image (sign-out / account switch).
  Future<void> clear();
}

/// File-backed implementation under `<app support>/receipts` on desktop and
/// `<documents>/receipts` on mobile. Legacy desktop images are copied once.
class FileReceiptImageStore implements ReceiptImageStore {
  FileReceiptImageStore({
    this.supportDirectory,
    this.documentsDirectory,
    this.isDesktopOverride,
  }) : _directory = null;

  /// Test seam: persist into an explicit directory.
  FileReceiptImageStore.withDirectory(Directory directory)
    : _directory = directory,
      supportDirectory = null,
      documentsDirectory = null,
      isDesktopOverride = null;

  final Directory? _directory;
  final DirectoryProvider? supportDirectory;
  final DirectoryProvider? documentsDirectory;
  final bool? isDesktopOverride;

  bool get _desktop =>
      isDesktopOverride ??
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows);

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

  @override
  Future<void> clear() async {
    try {
      final directory = await _resolveDirectory();
      await _deleteReceipts(directory);
      if (_desktop) {
        await _deleteReceipts(await _legacyDirectory());
      }
    } catch (_) {
      // Cleanup is best effort.
    }
  }

  Future<void> _deleteReceipts(Directory directory) async {
    if (!await directory.exists()) {
      return;
    }
    await for (final entity in directory.list()) {
      if (entity is File && p.basename(entity.path).startsWith('receipt_')) {
        try {
          await entity.delete();
        } catch (_) {
          // Ignore individual failures.
        }
      }
    }
  }

  Future<Directory> _resolveDirectory() async {
    final existing = _directory;
    if (existing != null) {
      return existing;
    }
    if (!_desktop) {
      return _legacyDirectory();
    }

    Directory target;
    try {
      final support =
          await (supportDirectory ?? getApplicationSupportDirectory)();
      target = Directory(p.join(support.path, 'receipts'));
    } catch (_) {
      return _legacyDirectory();
    }

    try {
      final legacy = await _legacyDirectory();
      if (!await target.exists() || await _isEmpty(target)) {
        await _migrate(legacy, target);
      }
    } catch (_) {
      // A failed migration leaves the legacy directory in place.
    }
    return target;
  }

  Future<Directory> _legacyDirectory() async {
    final documents =
        await (documentsDirectory ?? getApplicationDocumentsDirectory)();
    return Directory(p.join(documents.path, 'receipts'));
  }

  Future<bool> _isEmpty(Directory directory) async {
    await for (final _ in directory.list()) {
      return false;
    }
    return true;
  }

  Future<void> _migrate(Directory legacy, Directory target) async {
    if (!await legacy.exists()) {
      return;
    }
    await target.create(recursive: true);
    await for (final entity in legacy.list()) {
      if (entity is! File || !p.basename(entity.path).startsWith('receipt_')) {
        continue;
      }
      final destination = File(p.join(target.path, p.basename(entity.path)));
      if (!await destination.exists()) {
        await entity.copy(destination.path);
      }
    }
  }
}
