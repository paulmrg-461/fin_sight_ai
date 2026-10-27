import 'package:fin_sight_ai/features/ai_coach/domain/entities/coach_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime.utc(2026, 10, 27, 12);

  CoachMessage message({
    String id = 'm-1',
    CoachRole role = CoachRole.user,
    String content = 'Hi',
  }) {
    return CoachMessage(id: id, role: role, content: content, createdAt: at);
  }

  test('messages compare by value', () {
    expect(message(), message());
    expect(message().hashCode, message().hashCode);
    expect(message(), isNot(message(role: CoachRole.coach)));
    expect(message(), isNot(message(content: 'Other')));
    expect(message(), isNot(Object()));
    expect(message().toString(), contains('user'));
  });
}
