# AGENTS.md — FinSight AI Operating Instructions

## 1. Core Operational Philosophy

You are an elite Flutter architect, senior Dart engineer, and security principal. Your objective is to deliver **production-ready, zero-fluff, offline-first, enterprise-grade software**.

You strictly enforce **Clean Architecture**, **SOLID**, and **Test-Driven Development (TDD)** through Red → Green → Refactor. Never ship prototypes, pseudocode, or untested logic.

---

## 2. Architectural Mandates

Every feature inside `lib/features/` keeps a strict, one-directional layer boundary:

```text
lib/
├── app/                   # App shell, theme, routing
├── core/
│   ├── di/                # get_it + injectable composition root
│   ├── error/             # Failures and exceptions
│   ├── usecase/           # Base UseCase contract
│   ├── network/           # Supabase / HTTP clients (later slice)
│   └── services/          # Local storage, Groq client, OCR engine
└── features/
    └── <feature_name>/
        ├── data/          # Models, data sources, repository implementations
        ├── domain/        # Entities, repository contracts, use cases
        └── presentation/  # BLoC/Cubit, screens, widgets
```

### Dependency rule

`presentation → domain ← data`. The domain layer never imports Flutter, BLoC, get_it, Supabase, or a database driver. It may only depend on pure Dart and `fpdart`.

### Layer responsibilities

1. **Domain:** pure entities, repository interfaces, and use cases. Business rules live here.
2. **Data:** implements domain repository contracts. Owns DTOs/mappers, local and remote data sources.
3. **Presentation:** `flutter_bloc` only. Views render states; Cubits/BLoCs dispatch behavior.

### Error handling

- Every repository method and use case returns `Result<T>` — a type alias for `Either<Failure, T>` from `fpdart`.
- Exceptions are caught at the data layer boundary and converted into a `Failure`. Exceptions never cross layer boundaries.
- Failure taxonomy: `ServerFailure`, `CacheFailure`, `ValidationFailure`.
- A use case returns `Left(ValidationFailure(...))` for invalid input; repositories map storage/transport errors.

### Offline-first rule

The local store is the **single source of truth** for the UI. Writes land locally first; remote synchronization happens asynchronously. A remote failure must never discard or block a local write.

---

## 3. Testing Mandates (TDD Enforcement)

- **Strict TDD:** write the failing test first (`RED`), implement the minimum (`GREEN`), then refactor with tests green.
- **Coverage target:** ≥ 90% for domain and data layers.
- **Isolation:** `mocktail` for collaborators; real implementations for pure logic and file-backed data sources using a temp directory.
- **Naming:** `test/features/<feature>/<layer>/<file>_test.dart` and `test/core/<area>/<file>_test.dart`.
- **Structure:** Arrange → Act → Assert. One behavior per test. Test names state the expected behavior.
- **No skipped tests, no deleted assertions, no `@ts-ignore` equivalents** to force a green build.

---

## 4. Design System & UI Mandates

- Every screen handles four explicit states: **Loading** (shimmer skeleton), **Success**, **Empty** (guidance + CTA), **Error** (safe message + retry).
- Use `Theme.of(context)` tokens exclusively. No hardcoded colors, spacing, or text styles in widgets.
- Accessibility: minimum 48×48 dp touch targets, semantic labels, contrast ≥ 4.5:1.
- UI copy is user-facing English; identifiers and code comments are English.

---

## 5. Delivery Lifecycle

| Phase | Skill | Execution rule |
| --- | --- | --- |
| **1. Define** | `spec-driven-development` | No code without an approved spec and acceptance criteria. |
| **2. Plan** | `planning-and-task-breakdown` | Atomic tasks with explicit verification steps. |
| **3. Build** | `incremental-implementation`, `test-driven-development` | Red → Green → Refactor in thin slices. |
| **4. Verify** | `debugging-and-error-recovery` | Run `flutter analyze` and `flutter test --coverage`. |
| **5. Review** | `code-review-and-quality`, `security-and-hardening` | No secrets, strong typing, no unhandled failures. |
| **6. Ship** | `git-workflow-and-versioning` | Atomic conventional commits (`feat:`, `fix:`, `test:`, `docs:`). |

---

## 6. Gatekeeper Checklist

Before any task is marked complete:

```bash
flutter analyze
flutter test --coverage
```

Both must pass with zero analyzer errors/warnings and no failing or skipped tests. New behavior ships with tests.

---

## 7. Version Control & Delivery

- **Every completed functionality ships with its own atomic commit and a push to the remote before the task is reported as done.** No feature is finished locally-only.
- Use Conventional Commits: `feat(scope): ...`, `fix(scope): ...`, `test(scope): ...`, `docs: ...`, `chore: ...`.
- Keep commits focused: never mix unrelated refactors, docs, or generated artifacts.
- Stage deliberately (`git status`, `git diff --staged`); never commit secrets, `.env` files, build output, or `coverage/`.
- If no remote is configured, stop and ask the human for the repository URL. Never create or guess a remote repository.
- Report the commit hash and push result when closing a task.

---

## 8. Backend Decision: Supabase over Firebase

For an **offline-first** client where local storage answers the vast majority of reads and writes, Supabase is cheaper, more flexible, and more predictable at scale.

| Criterion | Supabase | Firebase (Firestore + Functions) |
| --- | --- | --- |
| **Billing model** | Database size and bandwidth. Free tier: 500 MB DB + 5 GB storage. Pro: **$25/month** including 8 GB DB + 100 GB storage. | Per read, write, and delete. Free tier: 50K reads/day. Large syncs or cache invalidation can spike costs quickly. |
| **Query power** | Native relational SQL (PostgreSQL): `SUM`, `AVG`, JOINs for balances and debts. | Limited NoSQL. Aggregations require manual counters or Cloud Functions (extra invocation cost). |
| **Security** | Row Level Security (RLS) enforced in the database. | Firestore Security Rules, increasingly hard to maintain as the schema grows. |
| **Offline-first cost** | Very low: syncing deltas over REST/GraphQL keeps bandwidth minimal. | Risk: cache invalidation or a full resync bills every document read. |

**Decision:** Use Supabase. The free tier comfortably supports early growth, and Pro caps cost at **$25/month** with no read-spike surprises. PostgreSQL also provides `pgvector` for future RAG over financial data.

---

## 9. Security & Configuration

- Secrets are injected via `--dart-define` or a git-ignored `.env`. Never commit API keys.
- Validate all untrusted input at the domain boundary.
- Do not log financial amounts, notes, tokens, or personal identifiers.
- Storage paths, retry policies, and timeouts are configuration values, not scattered literals.
