# Plan 012: Defer non-critical startup loads (PERF-02)

> **Executor instructions**: Measure before changing anything. Follow the steps
> in order; keep the dashboard the only blocking startup load. Update the status
> row and the plans index.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: 010
- **Category**: perf
- **Planned at**: commit 950eb3a, 2026-10-26

## Why this matters

With 300 seeded transactions, the Linux benchmark logs 199 ms from `pumpApp`
to the first dashboard frame (`Balance`) inside the full suite, but 1018–1128 ms
when the benchmark runs alone in a fresh test process. The cold number suggests
first-use deserialization or JIT warmup, not dashboard reads. The dashboard
itself performs only two range reads, so the remaining cost is startup work
that runs before or alongside the first frame:

- `main.dart` awaits `ProcessDueScheduledPaymentsUseCase` before `runApp`.
- Every bloc loads eagerly at startup: transactions, debts, receivables, OCR
  receipts, dashboard, budgets, wallets, categories, and schedules.
- Seeded data also queues 300 sync operations, so sync-status work grows with
  the number of local writes.

The first frame should not wait for screens the user has not opened.

## Target

First dashboard frame at or below **600 ms** with 300 transactions across three
months, measured by the existing integration benchmark.

## Steps

1. **Instrument first.** Log a timestamp per startup load (or capture a DevTools
   timeline) in both a cold single-test process and the warm full suite so the
   cost of each bloc load and `ProcessDueScheduledPaymentsUseCase` is visible.
   Do not guess; the 199 ms vs 1 s gap may be warmup rather than data volume.
2. **Split critical from deferred.**
   - Critical before the first frame: env/theme/locale, auth restore, dashboard.
   - Deferred until after the first frame: transactions list, debts, receivables,
     receipts, budgets, wallets, categories, AI coach, scheduled payments.
3. **Schedule deferred loads.** Trigger them from a post-frame callback (or a
   small `StartupLoader` with an ordered queue) so the dashboard renders first.
   Preserve current state semantics: deferred blocs still show loading and then
   loaded/empty/error.
4. **Move due-schedule processing off the blocking path.** Run it after the
   first frame, then surface the existing auto-created banner. Keep idempotency
   per schedule + due date; do not create duplicates on resume.
5. **Keep forms safe.** A form opened before categories/wallets finish loading
   must still work; verify pickers and defaults handle the short window.
6. **Re-measure.** Run the seeded benchmark three times and record the numbers.
   If startup remains above 600 ms, capture which deferred load still blocks and
   address that before closing the plan.

## Test plan

- Unit/widget: dashboard renders before deferred blocs emit loaded.
- Integration: seeded benchmark logs a number at or below 600 ms.
- Integration: schedules still auto-create once the deferred pass completes.
- Existing suite stays green (no skipped assertions).

## Done criteria

- [ ] Startup loads are explicitly split into critical and deferred.
- [ ] Due schedules are processed after the first frame without duplicates.
- [ ] Seeded benchmark runs three times at or below 600 ms.
- [ ] `flutter analyze`, unit coverage, coverage gate, Linux integration pass.
- [ ] `plans/README.md` checked off.

## STOP conditions

- A deferred load is required to compute the first dashboard frame.
- Moving due-schedule processing changes the auto-created banner contract.
- Auth restore must stay blocking for session-gated routing; keep it critical.

## Maintenance notes

- New blocs added to the shell load deferred until first use unless the
  dashboard needs them.
- Revisit Hive indices separately; this plan is scheduling, not storage.
