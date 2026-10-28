import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

typedef DirectoryProvider = Future<Directory> Function();

/// Chooses the directory that owns the Hive boxes.
///
/// Desktop platforms used to resolve `getApplicationDocumentsDirectory`, which
/// on Linux is the user's `~/Documents` folder. Ledger boxes now live in the
/// application support directory there, and the first launch copies any legacy
/// `*.hive` files across without deleting the originals.
class HiveStorageLocation {
  const HiveStorageLocation({
    this.supportDirectory,
    this.documentsDirectory,
    this.isDesktopOverride,
  });

  final DirectoryProvider? supportDirectory;
  final DirectoryProvider? documentsDirectory;
  final bool? isDesktopOverride;

  bool get isDesktop =>
      isDesktopOverride ??
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows);

  Future<Directory> resolve() async {
    if (!isDesktop) {
      return _documents();
    }

    Directory support;
    try {
      support = await _support();
    } catch (_) {
      // Never block startup on a missing XDG directory.
      return _documents();
    }

    try {
      if (!await support.exists()) {
        await support.create(recursive: true);
      }
      if (await _hasHiveFiles(support)) {
        return support;
      }

      final documents = await _documents();
      if (p.equals(documents.path, support.path)) {
        return support;
      }
      await _migrate(documents, support);
      return support;
    } catch (_) {
      return support;
    }
  }

  Future<Directory> _support() async {
    final provider = supportDirectory ?? getApplicationSupportDirectory;
    return provider();
  }

  Future<Directory> _documents() async {
    final provider = documentsDirectory ?? getApplicationDocumentsDirectory;
    return provider();
  }

  Future<bool> _hasHiveFiles(Directory directory) async {
    if (!await directory.exists()) {
      return false;
    }
    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith('.hive')) {
        return true;
      }
    }
    return false;
  }

  Future<void> _migrate(Directory documents, Directory support) async {
    if (!await documents.exists()) {
      return;
    }

    final sources = <File>[];
    await for (final entity in documents.list()) {
      if (entity is File && entity.path.endsWith('.hive')) {
        sources.add(entity);
      }
    }
    if (sources.isEmpty) {
      return;
    }

    final copied = <File>[];
    try {
      for (final source in sources) {
        final target = File(p.join(support.path, p.basename(source.path)));
        await source.copy(target.path);
        copied.add(target);
      }
    } catch (_) {
      // A partial migration is worse than none: retry on the next launch.
      for (final file in copied) {
        try {
          await file.delete();
        } catch (_) {
          // Ignore cleanup failures.
        }
      }
    }
  }
}
