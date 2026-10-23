import 'dart:io';

/// Enforces the project's 90% domain/data coverage target from lcov.info.
void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    stderr.writeln(
      'coverage/lcov.info not found. Run flutter test --coverage.',
    );
    exit(2);
  }

  final records = <_Record>[];
  String? current;
  var linesFound = 0;
  var linesHit = 0;

  for (final raw in file.readAsLinesSync()) {
    final line = raw.trim();
    if (line.startsWith('SF:')) {
      current = line.substring(3);
      linesFound = 0;
      linesHit = 0;
    } else if (line.startsWith('LF:')) {
      linesFound = int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      linesHit = int.parse(line.substring(3));
      if (current != null) {
        records.add(_Record(current, linesFound, linesHit));
      }
    }
  }

  final groups = <String, List<_Record>>{};
  for (final record in records) {
    final group = _groupFor(record.path);
    if (group != null) {
      groups.putIfAbsent(group, () => []).add(record);
    }
  }

  const threshold = 90.0;
  var failed = false;
  final names = groups.keys.toList()..sort();

  stdout.writeln(
    'Coverage (domain/data, threshold ${threshold.toStringAsFixed(0)}%):',
  );
  for (final name in names) {
    final files = groups[name]!;
    final found = files.fold<int>(0, (sum, r) => sum + r.found);
    final hit = files.fold<int>(0, (sum, r) => sum + r.hit);
    final percent = found == 0 ? 100.0 : hit / found * 100;
    final status = percent >= threshold ? 'OK' : 'FAIL';
    stdout.writeln(
      '  ${name.padRight(18)} ${percent.toStringAsFixed(1).padLeft(6)}%  $status',
    );
    if (percent < threshold) {
      failed = true;
    }
  }

  if (failed) {
    stderr.writeln('\nCoverage gate failed.');
    exit(1);
  }
  stdout.writeln('\nCoverage gate passed.');
}

String? _groupFor(String path) {
  final match = RegExp(r'lib/features/([^/]+)/(domain|data)/').firstMatch(path);
  if (match != null) {
    return '${match.group(1)} ${match.group(2)}';
  }
  if (path.startsWith('lib/core/')) {
    return 'core';
  }
  return null;
}

class _Record {
  const _Record(this.path, this.found, this.hit);

  final String path;
  final int found;
  final int hit;
}
