# Spec: scheduled payments

## Objective

Record recurring expenses (rent, credits, subscriptions, phone plans, insurance, …) once and let the
app create the matching expense automatically when each period is due.

## Model

`ScheduledPaymentEntity`:

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` | UUID v4 |
| `name` | `String` | e.g. “Rent”, “Netflix”, “Phone plan” |
| `amount` | `Double` | Positive, rounded to 2 decimals |
| `category` | `String` | Must exist in the category catalog (non-archived at creation) |
| `frequency` | `PaymentFrequency` | `monthly` or `yearly` |
| `nextDueDate` | `DateTime` | Normalized to midnight; the next charge date |
| `dayOfMonth` | `int` | 1–31, preserved so 31st payments clamp to short months without drifting |
| `walletId` | `String?` | Bank/cash wallet for the generated expense |
| `notes` | `String` | Optional, ≤ 500 characters |
| `isActive` | `bool` | Paused schedules are kept but never processed |
| `createdAt` / `updatedAt` / `lastPaidAt` | `DateTime?` | Audit fields |

## Date rules

- Monthly advance: next month, using `dayOfMonth` clamped to the month length.
  Jan 31 → Feb 28 → Mar 31 (no drift).
- Yearly advance: same month/day next year, clamping Feb 29 → Feb 28.
- A payment is **due** when normalized `nextDueDate <= today` and `isActive`.

## Behavior (user decision)

When the app starts, and when the scheduled-payments screen loads or a payment is added, due payments
are processed:

1. An expense transaction is created locally with the payment name as description, its category,
   amount, wallet, and the due date.
2. Generated transactions use a deterministic UUID v5 (`scheduled:<id>:<dueDate>`), so a retry can
   never duplicate a charge.
3. `nextDueDate` advances period by period until it is in the future; missed periods are all recorded
   (guard: 60 iterations).
4. The UI shows an in-app banner with how many expenses were auto-created.

“Pay now” records the expense immediately (dated today) and advances the schedule, even if the next
due date is in the future. Pausing stops future automatic expenses; deleting removes the schedule but
never deletes expenses already generated.

Budgets, dashboards, and wallets only see generated **transactions**; upcoming schedules are not
projected (user decision).

## Use cases

- `GetScheduledPaymentsUseCase`
- `AddScheduledPaymentUseCase` (validates name, amount, category, frequency, due date)
- `SetScheduledPaymentActiveUseCase`
- `DeleteScheduledPaymentUseCase`
- `PayScheduledPaymentUseCase`
- `ProcessDueScheduledPaymentsUseCase(DateTime now)`

## Persistence

- Hive `scheduled_payments` box, JSON maps.
- Repository depends on `TransactionRepository` to persist generated expenses, which enqueue normal
  sync operations. Schedules themselves are local-only in this slice.

## Presentation

- `ScheduledPaymentBloc`: load, add, pause/resume, delete, pay now, process due.
  States: initial, loading, loaded (list + auto-created count + optional error), empty, failure.
- `/scheduled` screen: list cards with amount, category, frequency, next due date, overdue badge,
  pause/resume, pay now, delete; FAB adds a payment; empty state explains the feature.
- Add form: name, amount, category, frequency, next due date, wallet, notes.
- Dashboard quick action and Settings entry point.

## Localization

All copy from ARB: `scheduledPayments`, `scheduledPaymentsDescription`, `addScheduledPayment`,
`newScheduledPayment`, `paymentName`, `paymentNameRequired`, `frequency`, `monthly`, `yearly`,
`nextDueDate`, `payNow`, `pausePayment`, `resumePayment`, `paused`, `dueToday`, `overdue`,
`noScheduledPayments`, `noScheduledPaymentsBody`, `addFirstScheduledPayment`,
`autoCreatedPayments(count)`, `deleteScheduledPayment`, `deleteScheduledPaymentQuestion`,
`deleteScheduledPaymentBody`, `notesOptional`, `scheduledFor`.

## Tests

- Date math: month-end clamping, leap years, multi-period catch-up.
- Entity equality and due detection.
- Hive CRUD, processing creates exactly one expense per period (idempotent UUID), active-only, pay-now.
- Use-case validation and failure mapping.
- BLoC transitions, auto-created count, discount errors.
- Widget and integration flow: create schedule due today → expense appears → pause → delete.
- Coverage ≥ 90% for domain and data.
