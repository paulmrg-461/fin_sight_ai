# Plan 009: Add due-date reminders and a committed-cashflow projection

> **Executor instructions**: This is a design-and-build plan with platform risk.
> Complete Phase A (pure Dart projection) first; Phase B (notifications) may be
> blocked if the plugin does not support the current Flutter beta. Do not
> improvise platform workarounds. Update the status row and report blockers.
>
> **Drift check**: `git diff --stat 4e42297..HEAD -- lib/features/scheduled_payments lib/features/debts lib/main.dart pubspec.yaml android ios`

## Status

- **Priority**: P3
- **Effort**: L
- **Risk**: MED
- **Depends on**: 003
- **Category**: direction
- **Planned at**: commit `4e42297`, 2026-10-23
- **Status**: IN PROGRESS. Phase A DONE (pure projection use case + 30/90-day card). Phase B BLOCKED: `android/` and `ios/` are excluded from version control in this environment and the notification plugin needs platform setup; no workaround attempted.

## Why this matters

Scheduled payments only process when the app starts or the screen loads. The
"rent never slips" promise is false if the user does not open the app. And every
dashboard widget is backward-looking: there is no view of what is already
committed for the next 30/90 days.

This plan adds (A) a pure-Dart committed-cashflow projection and (B) local
notifications for upcoming due dates, behind a testable interface.

## Current state

- `lib/features/scheduled_payments/domain/entities/scheduled_payment_entity.dart`
  — `nextDueDate`, `frequency`, `dayOfMonth`, `isActive`.
- `lib/features/scheduled_payments/domain/services/schedule_calculator.dart` —
  `advanceOnce`, `advancePast`.
- `lib/features/scheduled_payments/domain/usecases/scheduled_payment_usecases.dart`
  — CRUD/pay/process.
- `lib/features/scheduled_payments/presentation/screens/scheduled_payment_screen.dart`
  — list + FAB; no projection card.
- `lib/features/debts/domain/entities/debt_entity.dart` — `remainingAmount`,
  `minimumPayment`, `nextDueDate`-equivalent `dueDate`.
- `lib/main.dart:40-66` — startup processing and BLoC creation.
- `pubspec.yaml` has no notifications/timezone dependency. Android manifest and
  iOS plist are minimal.

Conventions: domain stays pure Dart; platform services live in
`lib/core/services/` behind interfaces and are faked in tests. See
`lib/core/services/receipt_image_picker.dart`.

## Commands you will need

| Purpose | Command | Expected |
|---|---|---|
| Dependencies | `flutter pub add flutter_local_notifications timezone` | resolves |
| Format | `dart format --output=none --set-exit-if-changed lib test integration_test tool` | 0 changed |
| Analyze | `flutter analyze` | No issues |
| Unit | `flutter test --coverage` | all pass |
| Coverage | `dart run tool/check_coverage.dart` | passed |
| Integration | `flutter test -d linux integration_test/app_flow_test.dart` | all pass |

## Scope

**In scope**
- `lib/features/scheduled_payments/domain/**` (projection)
- `lib/core/services/reminder_scheduler.dart` (new interface)
- `lib/core/services/local_reminder_scheduler.dart` (new implementation)
- `lib/main.dart`, `lib/app/app.dart` if a bootstrap hook is needed
- `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`
- `lib/features/scheduled_payments/presentation/**`, `lib/l10n/*.arb`
- tests: projection use case, scheduler fake, widget card

**Out of scope**
- Background execution to auto-create expenses while the app is closed (a
  separate, riskier feature).
- Server push notifications.
- Editing schedules (plan 008 follow-up).

## Phase A: Committed cashflow projection

### Step A1: Domain model and use case

Add `lib/features/scheduled_payments/domain/entities/committed_cashflow.dart`:

```dart
class CommittedPayment {
  const CommittedPayment({
    required this.date,
    required this.name,
    required this.amount,
    required this.category,
    required this.source, // scheduledPayment | debtMinimum
  });
  ...
}

class CommittedCashflow {
  const CommittedCashflow({required this.start, required this.end, required this.payments});
  double get total => payments.fold(0, (sum, p) => sum + p.amount);
}
```

Add `GetCommittedCashflowUseCase` that:
- accepts `CommittedCashflowParams({required DateTime from, required int days})`;
- takes `GetScheduledPaymentsUseCase` and `GetDebtsUseCase` (or repositories);
- expands active schedules from `nextDueDate` using `ScheduleCalculator.advanceOnce`
  until `from + days`, including multiple periods;
- adds active debts' `minimumPayment` on their due day within the window;
- returns payments sorted by date.

Validate `days` is 30 or 90 (or 1..365) and `from` normalized.

### Step A2: UI card

On `ScheduledPaymentScreen` (above the list), add a card:
- title `l10n.committedNext30Days` / `l10n.committedNext90Days`;
- total via `MoneyText`;
- a compact list of the next 3 payments (date, name, amount);
- empty state text when no commitments.

Use a new `CommittedCashflowCard` widget fed by a `BlocBuilder`/`FutureBuilder`
or a small `CommittedCashflowCubit`. Do not fetch inside `build`; load in
`initState`/bloc event.

### Step A3: Tests

- Monthly schedule with two occurrences in 60 days.
- Yearly schedule with one occurrence.
- Paused schedule excluded.
- Debt minimum included on its due date.
- Window boundaries inclusive.

**Verify**: `flutter test test/features/scheduled_payments/domain` green.

## Phase B: Local due-date reminders

### Step B1: Interface and fake

Add `lib/core/services/reminder_scheduler.dart`:

```dart
abstract interface class ReminderScheduler {
  Future<void> initialize();
  Future<void> scheduleFor(ScheduledPaymentEntity payment);
  Future<void> cancelFor(String paymentId);
  Future<void> cancelAll();
}
```

The implementation wraps the plugin; tests use `FakeReminderScheduler` and
assert calls. `ScheduledPaymentBloc` (or the use cases) invokes:
- `scheduleFor` after add/pay/resume;
- `cancelFor` after pause/delete.

Use deterministic notification ids derived from the payment id (e.g. stable
hash of the id, masked to 32-bit) so rescheduling replaces the old one.

### Step B2: Platform setup

- Android: request `POST_NOTIFICATIONS` (API 33+), add the receiver/permissions
  required by the plugin, handle `exactAllowWhileIdle` only if the plugin
  supports it; otherwise use inexact daily scheduling and document the drift.
- iOS: request permissions on first schedule; add the plugin's initialization
  in `AppDelegate` per its README.
- Desktop/web: no-op implementation (`NoopReminderScheduler`) so tests and
  Linux integration remain deterministic.

### Step B3: Bootstrap

In `main`, initialize the scheduler before `runApp` (after
`configureDependencies`). Do not await a permission prompt during tests; guard
with a `kIsWeb`/platform check and the no-op fake in the harness.

**STOP** if `flutter pub add` cannot resolve a plugin compatible with Flutter
3.50 beta. Report the resolution error; do not downgrade Flutter.

## Test plan

- Projection unit tests (Phase A).
- Widget test for the card with a fake use case.
- Scheduler fake tests: add → schedule, pause/delete → cancel, pay → reschedule.
- Integration: existing flows remain green; add a flow that opens the screen and
  sees the projection card.

## Done criteria

- [x] Projection card shows 30/90-day totals and next payments.
- [x] Projection use case is pure Dart and tested.
- [ ] Reminder scheduler is invoked on add/pause/delete/pay.
- [ ] Linux integration uses a no-op scheduler and passes.
- [ ] Android/iOS setup documented in `README.md`.
- [ ] `flutter analyze`, unit coverage, coverage gate pass.
- [ ] `plans/README.md` updated (including BLOCKED if Phase B cannot resolve).

## STOP conditions

- Plugin resolution fails on the beta SDK.
- Exact alarms require a Play Store permission declaration the product has not
  approved.
- Notifications need a background isolate to read Hive; do not add one here.

## Maintenance notes

- Background auto-posting remains app-open-only; document the limitation in the
  scheduled-payments spec.
- If schedules are edited later, reschedule notifications in the update path.
- Reviewer: verify notification text never includes account identifiers or
  tokens.
