# Spec: AI Coach

## Objective

Use Groq chat completions to generate personalized financial insights from the user's transaction history, with deterministic prompts and safe error handling.

## Entity

`FinancialInsightEntity extends Entity`

| Field | Type | Rules |
| --- | --- | --- |
| `id` | `String` | UUID v4 |
| `type` | `InsightType` | `suggestion`, `alert`, `analysis` |
| `content` | `String` | Non-empty model reply |
| `timestamp` | `DateTime` | Generation time |
| `relatedTransactionId` | `String?` | Optional link to a transaction |

## Repository

```dart
ResultFuture<List<FinancialInsightEntity>> getFinancialInsights(String context);
ResultFuture<FinancialInsightEntity> analyzeSpending(String context);
ResultFuture<FinancialInsightEntity> getSavingsSuggestions(String context);
```

## Use cases

`GetInsightsUseCase`, `AnalyzeSpendingUseCase`, `GetSavingsSuggestionsUseCase` — each takes the financial context string.

## Data

- `AiCoachDatasource.callGroqApi(prompt, context)`.
- `GroqApiDatasource` posts to `https://api.groq.com/openai/v1/chat/completions` with `llama-3.3-70b-versatile`, a system prompt, and the prompt + context as the user message. Timeout: 15s.
- `AppEnv.groqApiKey` comes from `--dart-define` or `.env`.
- Error codes: `groq_not_configured`, `groq_http_<status>`, `groq_invalid_response`, `groq_timeout`, `groq_network_error`.
- `PromptTemplates` cover insights, spending analysis, savings, budget optimization (50/30/20), and debt payoff (avalanche/snowball).
- `InsightParser` accepts JSON arrays, objects, fenced JSON, or plain text (fallback analysis).
- `AiCoachRepositoryImpl` builds prompts, calls Groq, maps failures to `ServerFailure`, and assigns ids/timestamps.

## Presentation

`AiCoachBloc` events: `LoadInsights`, `AnalyzeSpending`, `GetSuggestions`.

The bloc builds a context from real transactions (`Income`, `Expenses`, `Balance`, top categories) via `GetTransactionsUseCase`.

States: initial, loading, loaded, empty, failure. New analyses are prepended to the existing list, preserving a chat-like history.

`AiCoachScreen` renders `InsightCard` widgets with type-specific colors/icons and action buttons for analysis, savings tips, and refresh.

## Verification

```bash
flutter analyze
flutter test --coverage
```

## Context

The prompt context includes transaction totals and top expense categories plus active debt
information: count, total remaining, total minimum payments, and the highest annual rate. Debt
read failures are ignored so coaching still works.

## History

Every successful generation is appended to `ai_insights` as an
`InsightHistoryEntry` (timestamp, kind `insights`/`analysis`/`suggestions`, contents). History is
per language, newest first, capped at 20 batches, and cleared with account data. The coach screen
exposes it in a **History** expansion; the latest batch remains the offline fallback.

## Free-form chat

`/ai-coach/chat` runs a persisted conversation through `CoachChatBloc`:

- `AskCoachUseCase` validates the question (≤500 chars) and calls
  `AiCoachRepository.askCoach`, which uses the chat prompt and the shared
  `CoachContextBuilder` context. Answers are plain text, not JSON.
- `CoachMessage` (user/coach) is stored in `ai_insights` via `CoachChatStore`,
  newest 100 messages, cleared with account data.
- The user turn is persisted before the network call; a failure keeps the
  question visible and surfaces a localized error.
- The UI shows suggestion prompts, bubbles, send progress, and a confirmed clear
  action. Entry point: chat icon in the AI Coach app bar.
