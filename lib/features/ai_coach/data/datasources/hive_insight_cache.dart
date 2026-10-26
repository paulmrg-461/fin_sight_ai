import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/app_boxes.dart';
import '../../domain/entities/financial_insight_entity.dart';
import '../../domain/repositories/insight_cache.dart';

/// Hive-backed cache for the last generated insights, keyed by language.
@LazySingleton(as: InsightCache)
class HiveInsightCache implements InsightCache {
  const HiveInsightCache(this._boxes);

  static const String _prefix = 'insights_';

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
    List<FinancialInsightEntity> insights,
  ) async {
    try {
      await _box.put('$_prefix${_language(languageCode)}', {
        'savedAt': DateTime.now().toUtc().toIso8601String(),
        'insights': [
          for (final insight in insights)
            {
              'id': insight.id,
              'type': insight.type.name,
              'content': insight.content,
              'timestamp': insight.timestamp.toUtc().toIso8601String(),
              'relatedTransactionId': insight.relatedTransactionId,
            },
        ],
      });
    } catch (_) {
      // Cache writes are best effort; never fail the AI response.
    }
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
