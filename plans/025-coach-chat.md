# Plan 025: Free-form coaching chat with persisted conversation

> **Executor instructions**: Reuse the shared financial context builder and the
> existing Groq datasource. Never send account identifiers.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: 019, 020, 024
- **Category**: direction
- **Planned at**: commit bb49352, 2026-10-27
- **Status**: DONE

## Why this matters

The coach could generate fixed insights but could not answer “should I pay the
card or the loan first?” with the user's real numbers, and there was no
conversation memory.

## What shipped

- `CoachContextBuilder`: one shared context (transactions, categories, active
  debt totals/rates, response language) for insights and chat.
- `AskCoachUseCase` + repository/datasource `askCoach`: plain-text answer,
  500-character question limit, empty-response protection.
- `CoachMessage` + `CoachChatStore`/`HiveCoachChatStore`: conversation persisted
  in `ai_insights` (newest 100 messages, cleared on sign-out).
- `CoachChatBloc`: loads history, appends the user turn immediately, builds
  context, calls the model, appends the answer, keeps the question on failure.
- `/ai-coach/chat` screen: bubbles, suggestions, input, send progress, clear
  conversation with confirmation; entry from the coach app bar.
- All copy EN/ES.

## Tests

- Use case validation/trimming/failure; repository prompt/plain-text/empty/error.
- Hive store append/read/cap/corrupt/clear.
- BLoC load, send success, failure keeps question, clear.
- Integration: open chat, tap a suggestion, render the model answer.

## Done criteria

- [x] Users can ask free-form questions with real financial context.
- [x] Conversation persists locally and can be cleared.
- [x] Analyze, coverage gate, and Linux integration pass.
