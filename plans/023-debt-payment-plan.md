# Plan 023: Debt payment plan and current-debt overview

> **Executor instructions**: Keep the amortization math in the pure domain
> calculator. The dashboard card must read `DebtBloc`, not query storage.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: 008, 021
- **Category**: direction
- **Planned at**: commit 6056187, 2026-10-27
- **Status**: DONE

## Why this matters

Debt detail only answered “when will I finish?”. Users also need the monthly
plan: how much goes to interest vs principal and how the balance falls. The
dashboard showed balances and receivables but not the debt still owed.

## What shipped

- Pure `DebtPaymentPlan`/`DebtInstallment` domain models and
  `DebtPayoffCalculator.buildPaymentPlan`:
  - monthly interest/principal split, remaining balance, final shortened payment;
  - total interest and total paid;
  - returns `null` when the payment cannot cover interest.
- `calculatePayoffDate` now derives from the same plan, so date and schedule can
  never disagree.
- `PayoffEstimate` carries the plan; the debt detail screen renders a **Payment
  plan** card with the totals and every installment.
- The payoff calculator falls back to the debt's minimum payment when the field
  is empty.
- Dashboard gains a **Current debts** card: active count, total remaining, next
  due creditor/date/minimum, tap to open `/debts`. It hides when no active debt.
- Amounts use `MoneyText` and all copy is EN/ES.

## Tests

- Calculator: zero-interest plan, interest/principal split with a shortened last
  payment, non-amortizing null.
- Domain model: equality/hash/toString for installments and plans.
- BLoC: payoff estimate includes a plan.
- Widget: dashboard debt card totals/next due and hidden state.
- Integration: create a debt, open details, calculate with the minimum payment,
  and see the plan.

## Done criteria

- [x] Payment plan totals and installments render in debt details.
- [x] Dashboard shows current debts and hides when none are active.
- [x] Analyze, unit coverage, coverage gate, and Linux integration pass.
