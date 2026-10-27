enum CoachRole { user, coach }

/// One turn in the free-form coaching conversation.
class CoachMessage {
  const CoachMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final CoachRole role;
  final String content;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachMessage &&
          other.id == id &&
          other.role == role &&
          other.content == content &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(id, role, content, createdAt);

  @override
  String toString() => 'CoachMessage($role, $createdAt)';
}
