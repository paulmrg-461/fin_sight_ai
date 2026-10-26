# Plan 020: Cache AI insights for offline use

> **Executor instructions**: Cache only successful model output. Never let a
> cache read/write failure change the network result.

## Status

- **Priority**: P3
- **Effort**: M
- **Risk**: LOW
- **Depends on**: 019
- **Category**: direction
- **Planned at**: commit 0e355ea, 2026-10-26
- **Status**: DONE

## Why this matters

Opening the AI Coach offline replaced previously generated insights with an
error. The advice the user already paid for (time/network) should remain visible.

## What shipped

- New user-owned Hive box `ai_insights`, opened at startup and cleared with the
  other account data on sign-out.
- `InsightCache` contract + `HiveInsightCache`, keyed by language (`en`/`es`),
  storing type, content, timestamp, and related transaction id.
- `AiCoachBloc`:
  - writes successful loads, analyses, and suggestions;
  - on a failed load, falls back to the cached list and flags it as saved;
  - on a failed analysis/suggestion, keeps the insights already on screen.
- `AiCoachLoaded.fromCache` drives a “Showing saved insights” banner.
- Corrupt entries are skipped; cache failures never surface to the user.

## Tests

- Cache: per-language reads, empty/corrupt entries, clear.
- BLoC: offline fallback, write on success, keep previous on analysis failure.
- Local data scope clears the new box on sign-out.

## Done criteria

- [x] Offline coach shows saved insights with a clear banner.
- [x] Cache is per language and cleared with account data.
- [x] Analyze, coverage gate, and Linux integration pass.
