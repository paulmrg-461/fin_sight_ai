import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/app_boxes.dart';
import '../../domain/entities/financial_insight_entity.dart';
import '../../domain/entities/insight_history_entry.dart';
import '../../domain/repositories/insight_cache.dart';

/// Hive-backed cache for the last generated insights, keyed by language.
@LazySingleton(as: InsightCache)
class HiveInsightCache implements InsightCache {
  const HiveInsightCache(this._boxes);

  static const String _prefix = 'insights_';
  static const String _historyPrefix = 'history_';
  static const int maxHistoryEntries = 20;

  final AppBoxes _boxes;

  Box<dynamic> get _box => _boxes.aiInsights;

  @override
  Future<List<FinancialInsightEntity>?> read(String languageCode) async {
    try {
      final raw = _box.get('$_prefix${_language(languageCode)}');
      if (raw is! Map) {
        return null;
      }
      final rows = raw['insights'];
      if (rows is! List) {
        return null;
      }
      final insights = <FinancialInsightEntity>[];
      for (final row in rows) {
        final insight = _fromJson(row);
        if (insight != null) {
          insights.add(insight);
        }
      }
      return insights.isEmpty
          ? null
          : List<FinancialInsightEntity>.unmodifiable(insights);
    } catch (_) {
      // A broken cache must never break the coach.
      return null;
    }
  }

  @override
  Future<void> write(
    String languageCode,
    List<FinancialInsightEntity> insights, {
    InsightHistoryKind kind = InsightHistoryKind.insights,
    DateTime? createdAt,
  }) async {
    try {
      final language = _language(languageCode);
      final savedAt = (createdAt ?? DateTime.now()).toUtc();
      final rows = [for (final insight in insights) _toJson(insight)];
      await _box.put('$_prefix$language', {
        'savedAt': savedAt.toIso8601String(),
        'insights': rows,
      });

      final history = await _readHistoryModels(language);
      history.insert(0, {
        'savedAt': savedAt.toIso8601String(),
        'kind': kind.name,
        'insights': rows,
      });
      await _box.put(
        '$_historyPrefix$language',
        history.take(maxHistoryEntries).toList(growable: false),
      );
    } catch (_) {
      // Cache writes are best effort; never fail the AI response.
    }
  }

  @override
  Future<List<InsightHistoryEntry>> readHistory(String languageCode) async {
    try {
      final rows = await _readHistoryModels(_language(languageCode));
      final entries = <InsightHistoryEntry>[];
      for (final row in rows) {
        final entry = _historyFromJson(row);
        if (entry != null) {
          entries.add(entry);
        }
      }
      return List<InsightHistoryEntry>.unmodifiable(entries);
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> _readHistoryModels(String language) async {
    final raw = _box.get('$_historyPrefix$language');
    if (raw is! List) {
      return [];
    }
    return [
      for (final row in raw)
        if (row is Map) Map<String, dynamic>.from(row),
    ];
  }

  Map<String, dynamic> _toJson(FinancialInsightEntity insight) => {
    'id': insight.id,
    'type': insight.type.name,
    'content': insight.content,
    'timestamp': insight.timestamp.toUtc().toIso8601String(),
    'relatedTransactionId': insight.relatedTransactionId,
  };

  InsightHistoryEntry? _historyFromJson(Map<String, dynamic> row) {
    final savedAt = row['savedAt'];
    final kind = row['kind'];
    final rows = row['insights'];
    if (savedAt is! String || kind is! String || rows is! List) {
      return null;
    }
    final parsedAt = DateTime.tryParse(savedAt);
    final parsedKind = InsightHistoryKind.values.asNameMap()[kind];
    if (parsedAt == null || parsedKind == null) {
      return null;
    }
    final insights = <FinancialInsightEntity>[];
    for (final value in rows) {
      final insight = _fromJson(value);
      if (insight != null) {
        insights.add(insight);
      }
    }
    if (insights.isEmpty) {
      return null;
    }
    return InsightHistoryEntry(
      createdAt: parsedAt,
      kind: parsedKind,
      insights: List<FinancialInsightEntity>.unmodifiable(insights),
    );
  }

  @override
  Future<void> clear() async {
    try {
      await _box.clear();
    } catch (_) {
      // Ignore cache cleanup failures.
    }
  }

  String _language(String code) {
    final normalized = code.trim().toLowerCase();
    return normalized.startsWith('es') ? 'es' : 'en';
  }

  FinancialInsightEntity? _fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final id = value['id'];
    final type = value['type'];
    final content = value['content'];
    final timestamp = value['timestamp'];
    if (id is! String || content is! String || timestamp is! String) {
      return null;
    }
    final parsedType = type is String
        ? InsightType.values.asNameMap()[type]
        : null;
    final parsedTimestamp = DateTime.tryParse(timestamp);
    if (parsedType == null || parsedTimestamp == null) {
      return null;
    }
    return FinancialInsightEntity(
      id: id,
      type: parsedType,
      content: content,
      timestamp: parsedTimestamp,
      relatedTransactionId: value['relatedTransactionId'] is String
          ? value['relatedTransactionId'] as String
          : null,
    );
  }
}
