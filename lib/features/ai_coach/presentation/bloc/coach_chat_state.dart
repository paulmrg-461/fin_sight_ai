import 'package:equatable/equatable.dart';

import '../../domain/entities/coach_message.dart';

sealed class CoachChatState extends Equatable {
  const CoachChatState();

  @override
  List<Object?> get props => const [];
}

final class CoachChatInitial extends CoachChatState {
  const CoachChatInitial();
}

final class CoachChatLoading extends CoachChatState {
  const CoachChatLoading();
}

final class CoachChatLoaded extends CoachChatState {
  const CoachChatLoaded(this.messages, {this.sending = false, this.error});

  final List<CoachMessage> messages;
  final bool sending;

  /// Non-fatal send error; the conversation is kept.
  final String? error;

  @override
  List<Object?> get props => [messages, sending, error];
}

final class CoachChatFailure extends CoachChatState {
  const CoachChatFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
