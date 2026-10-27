import 'package:equatable/equatable.dart';

sealed class CoachChatEvent extends Equatable {
  const CoachChatEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadCoachChat extends CoachChatEvent {
  const LoadCoachChat();
}

final class SendCoachMessage extends CoachChatEvent {
  const SendCoachMessage({required this.text, required this.languageCode});

  final String text;
  final String languageCode;

  @override
  List<Object?> get props => [text, languageCode];
}

final class ClearCoachChat extends CoachChatEvent {
  const ClearCoachChat();
}
