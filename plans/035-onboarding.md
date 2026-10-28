# Plan 035: First-run onboarding

> **Executor instructions**: The tour is a local overlay, not a router redirect.
> A settings failure must not trap the user.

## Status

- **Priority**: P2
- **Effort**: S
- **Risk**: LOW
- **Depends on**: 011
- **Category**: direction
- **Planned at**: commit 2627b9d, 2026-10-27
- **Status**: DONE

## What shipped

- `OnboardingService` + `HiveOnboardingService` (`onboarding_completed_v1` in
  settings); completion is best effort.
- `OnboardingGate` wraps the router child inside `MaterialApp.router`:
  - loading until the flag is read;
  - three-page tour with Skip/Next/Get started;
  - completion hides the tour without navigation.
- Pages: welcome, offline-first/privacy, and practical first steps.
- EN/ES copy; brand logo, theme colors, accessible page dots.

## Tests

- Widget: incomplete gate shows the tour and Skip reveals the app; completed gate
  goes straight through.
- Integration: first launch shows onboarding, Skip opens the dashboard, flag is
  persisted.

## Done criteria

- [x] Onboarding shows once per device and can be skipped.
- [x] Completion persists in settings.
- [x] Analyze, coverage gate, and Linux integration pass.
