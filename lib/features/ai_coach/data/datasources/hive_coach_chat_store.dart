import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/app_boxes.dart';
import '../../domain/entities/coach_message.dart';
import '../../domain/repositories/coach_chat_store.dart';

/// Hive-backed coaching conversation, capped to the newest messages.
@LazySingleton(as: CoachChatStore)
class HiveCoachChatStore implements CoachChatStore {
  const HiveCoachChatStore(this._boxes);

  static const String _key = 'chat_messages';
  static const int maxMessages = 100;

  final AppBoxes _boxes;

  Box<dynamic> get _box => _boxes.aiInsights;

  @override
  Future<List<CoachMessage>> read() async {
    try {
      final raw = _box.get(_key);
      if (raw is! List) {
        return const [];
      }
      final messages = <CoachMessage>[];
      for (final value in raw) {
        final message = _fromJson(value);
        if (message != null) {
          messages.add(message);
        }
      }
      return List<CoachMessage>.unmodifiable(messages);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> append(CoachMessage message) async {
    try {
      final messages = await read();
      final next = [...messages, message];
      final trimmed = next.length > maxMessages
          ? next.sublist(next.length - maxMessages)
          : next;
      await _box.put(_key, [for (final item in trimmed) _toJson(item)]);
    } catch (_) {
      // Conversation persistence is best effort.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _box.delete(_key);
    } catch (_) {
      // Ignore clear failures.
    }
  }

  Map<String, dynamic> _toJson(CoachMessage message) => {
    'id': message.id,
    'role': message.role.name,
    'content': message.content,
    'createdAt': message.createdAt.toUtc().toIso8601String(),
  };

  CoachMessage? _fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final id = value['id'];
    final role = value['role'];
    final content = value['content'];
    final createdAt = value['createdAt'];
    if (id is! String || role is! String || content is! String) {
      return null;
    }
    final parsedRole = CoachRole.values.asNameMap()[role];
    final parsedAt = createdAt is String ? DateTime.tryParse(createdAt) : null;
    if (parsedRole == null || parsedAt == null) {
      return null;
    }
    return CoachMessage(
      id: id,
      role: parsedRole,
      content: content,
      createdAt: parsedAt,
    );
  }
}
