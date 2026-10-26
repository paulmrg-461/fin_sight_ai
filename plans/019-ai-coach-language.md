# Plan 019: Answer AI coaching in the active language

> **Executor instructions**: Keep prompts as constants; append the language
> instruction to the per-request context. No locale dependency in the domain.

## Status

- **Priority**: P3
- **Effort**: S
- **Risk**: LOW
- **Depends on**: 004
- **Category**: i18n
- **Planned at**: commit 53e3fd4, 2026-10-26
- **Status**: DONE

## Why this matters

The app UI was fully EN/ES but AI insights always came back in English because
the prompts never told the model which language to use.

## What shipped

- `LoadInsights`, `AnalyzeSpending`, and `GetSuggestions` accept a
  `languageCode` (default `en`).
- `AiCoachBloc` appends “Write the response in Spanish/English.” to the context,
  including the empty-ledger case.
- The AI Coach screen reads `Localizations.localeOf(context)` and passes the
  active language with every request.
- Prompts and repository contracts stay unchanged and Flutter-free.

## Tests

- BLoC verifies the Spanish instruction reaches the insights use case.
- Existing EN flows keep the default.
- Full unit, coverage gate, and Linux integration stay green.

## Follow-ups

- Cached insights should store the language they were generated in; currently
  each tap regenerates from the active locale.

## Done criteria

- [x] Spanish locale requests Spanish output.
- [x] English remains the default.
- [x] Analyze, coverage gate, and integration pass.
