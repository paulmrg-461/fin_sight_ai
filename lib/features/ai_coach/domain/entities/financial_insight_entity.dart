import '../../../../core/domain/entity.dart';

/// Kind of coaching insight returned by the AI.
enum InsightType { suggestion, alert, analysis }

/// A single AI-generated financial insight.
class FinancialInsightEntity extends Entity {
  const FinancialInsightEntity({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    this.relatedTransactionId,
  });

  @override
  final String id;

  final InsightType type;
  final String content;
  final DateTime timestamp;
  final String? relatedTransactionId;

  FinancialInsightEntity copyWith({
    String? id,
    InsightType? type,
    String? content,
    DateTime? timestamp,
    String? relatedTransactionId,
  }) {
    return FinancialInsightEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      relatedTransactionId: relatedTransactionId ?? this.relatedTransactionId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinancialInsightEntity &&
          other.id == id &&
          other.type == type &&
          other.content == content &&
          other.timestamp == timestamp &&
          other.relatedTransactionId == relatedTransactionId;

  @override
  int get hashCode =>
      Object.hash(id, type, content, timestamp, relatedTransactionId);

  @override
  String toString() =>
      'FinancialInsightEntity(id: $id, type: $type, content: $content)';
}
