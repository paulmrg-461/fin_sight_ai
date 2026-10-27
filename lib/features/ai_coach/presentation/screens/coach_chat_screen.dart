import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/failure_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/coach_message.dart';
import '../bloc/coach_chat_bloc.dart';
import '../bloc/coach_chat_event.dart';
import '../bloc/coach_chat_state.dart';

/// Free-form conversation with the financial coach.
class CoachChatScreen extends StatefulWidget {
  const CoachChatScreen({super.key});

  @override
  State<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends State<CoachChatScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CoachChatBloc>().add(const LoadCoachChat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _languageCode => Localizations.localeOf(context).languageCode;

  void _send([String? suggestion]) {
    final text = suggestion ?? _controller.text;
    if (text.trim().isEmpty) {
      return;
    }
    _controller.clear();
    context.read<CoachChatBloc>().add(
      SendCoachMessage(text: text, languageCode: _languageCode),
    );
  }

  Future<void> _clear() async {
    final l10n = context.l10n;
    final bloc = context.read<CoachChatBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.clearChatQuestion),
        content: Text(l10n.clearChatBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(const ClearCoachChat());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.askCoach),
        actions: [
          BlocBuilder<CoachChatBloc, CoachChatState>(
            builder: (context, state) {
              final hasMessages =
                  state is CoachChatLoaded && state.messages.isNotEmpty;
              return IconButton(
                onPressed: hasMessages ? _clear : null,
                tooltip: l10n.clearChat,
                icon: const Icon(Icons.delete_sweep_outlined),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<CoachChatBloc, CoachChatState>(
        builder: (context, state) {
          return switch (state) {
            CoachChatInitial() || CoachChatLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            CoachChatFailure(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.failureText(message),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            CoachChatLoaded(:final messages, :final sending, :final error) =>
              Column(
                children: [
                  Expanded(
                    child: messages.isEmpty
                        ? _ChatEmpty(onSuggestion: _send)
                        : ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message =
                                  messages[messages.length - 1 - index];
                              return _MessageBubble(message: message);
                            },
                          ),
                  ),
                  if (sending) const LinearProgressIndicator(minHeight: 2),
                  if (error != null)
                    Container(
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.errorContainer,
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        context.failureText(error),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              decoration: InputDecoration(
                                hintText: l10n.askCoachHint,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: sending ? null : _send,
                            tooltip: l10n.send,
                            icon: const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          };
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == CoachRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _ChatEmpty extends StatelessWidget {
  const _ChatEmpty({required this.onSuggestion});

  final void Function(String suggestion) onSuggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final suggestions = [
      l10n.coachSuggestionOne,
      l10n.coachSuggestionTwo,
      l10n.coachSuggestionThree,
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.forum_outlined, size: 44, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text(
          l10n.coachChatEmptyTitle,
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.coachChatEmptyBody,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        for (final suggestion in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              onPressed: () => onSuggestion(suggestion),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(suggestion),
              ),
            ),
          ),
      ],
    );
  }
}
