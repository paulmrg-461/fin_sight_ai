# Plan 034: Golden coverage and a release APK CI job

> **Executor instructions**: Goldens must be committed; CI must not regenerate
> them. The release job uses placeholder defines, never real secrets.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: 033
- **Category**: quality
- **Planned at**: commit 809e2dd, 2026-10-27
- **Status**: DONE

## What shipped

- First golden test: dashboard `BudgetAlertsCard` with near-limit and over-limit
  rows (`test/.../goldens/budget_alerts_card.png`).
- `.gitignore` re-includes golden PNGs under `test/**/goldens/` (machine-level
  `*.png` excludes previously hid them).
- CI quality job now fails on golden drift via the normal test suite.
- New `release-apk` CI job builds a signed-with-debug-key release APK using
  `example.env` placeholders, proving the release manifest (INTERNET,
  desugaring, plugins) compiles.

## Notes

- Goldens are generated on Linux; if a different renderer ever changes pixels,
  regenerate intentionally and review the image in the PR.
- Release signing remains a product decision; the goal here is compile
  verification, not store distribution.

## Done criteria

- [x] Golden image is tracked and stable locally.
- [x] CI builds a release APK with placeholder config.
- [x] Analyze, coverage gate, and Linux integration pass.
