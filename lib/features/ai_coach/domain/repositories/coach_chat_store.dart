import '../entities/coach_message.dart';

/// Persists the free-form coaching conversation.
abstract interface class CoachChatStore {
  Future<List<CoachMessage>> read();

  Future<void> append(CoachMessage message);

  Future<void> clear();
}
