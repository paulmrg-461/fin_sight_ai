import 'dart:convert';

import '../../domain/entities/financial_insight_entity.dart';

/// A validated insight before ids and timestamps are assigned.
class ParsedInsight {
  const ParsedInsight({
    required this.type,
    required this.content,
    this.relatedTransactionId,
  });

  final InsightType type;
  final String content;
  final String? relatedTransactionId;
}

/// Parses Groq responses that should contain a JSON object or array.
///
/// Plain-text responses degrade to an `analysis` insight instead of failing.
class InsightParser {
  const InsightParser();

  static final RegExp _codeFence = RegExp(
    r'^```(?:json)?\s*|\s*```$',
    caseSensitive: false,
  );

  List<ParsedInsight> parse(String raw) {
    final cleaned = raw.replaceAll(_codeFence, '').trim();
    if (cleaned.isEmpty) {
      return const [];
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(cleaned);
    } catch (_) {
      return [ParsedInsight(type: InsightType.analysis, content: cleaned)];
    }

    final entries = decoded is List ? decoded : <dynamic>[decoded];
    final insights = <ParsedInsight>[];

    for (final entry in entries) {
      if (entry is String) {
        final content = entry.trim();
        if (content.isNotEmpty) {
          insights.add(
            ParsedInsight(type: InsightType.analysis, content: content),
          );
        }
        continue;
      }
      if (entry is! Map) {
        continue;
      }

      final content = entry['content'] ?? entry['insight'] ?? entry['message'];
      if (content is! String || content.trim().isEmpty) {
        continue;
      }

      final related = entry['relatedTransactionId'];
      insights.add(
        ParsedInsight(
          type: _typeOf(entry['type']),
          content: content.trim(),
          relatedTransactionId: related is String && related.trim().isNotEmpty
              ? related.trim()
              : null,
        ),
      );
    }

    if (insights.isEmpty) {
      return [ParsedInsight(type: InsightType.analysis, content: cleaned)];
    }
    return List<ParsedInsight>.unmodifiable(insights);
  }

  InsightType _typeOf(Object? raw) {
    if (raw is! String) {
      return InsightType.analysis;
    }
    return InsightType.values.asNameMap()[raw.toLowerCase().trim()] ??
        InsightType.analysis;
  }
}
