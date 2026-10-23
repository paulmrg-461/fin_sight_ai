# Supabase setup and RLS verification

## Apply the schema

Fastest option: open the Supabase **SQL Editor**, paste `supabase/apply_all.sql`,
and run it once.

Or apply the migrations with psql / the helper script:

```bash
export SUPABASE_DB_URL="postgresql://postgres:...@db.<project>.supabase.co:5432/postgres"
./supabase/apply_all.sh

# equivalent manual commands:
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/0001_init.sql
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/0002_tombstones.sql
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/0003_budgets.sql
```

For local development, disable **Confirm email** in
Authentication > Providers > Email (or confirm the email before signing in),
because Supabase currently reports `mailer_autoconfirm: false` for this
project.

`0001_init.sql` creates `transactions` and `debts` with owner-only RLS.
`0002_tombstones.sql` adds `deleted_at` so deletions can propagate between
devices.

## Authentication

The client signs in with Supabase Auth (email/password). The access token is
stored in platform secure storage and sent as the `Authorization: Bearer`
header for PostgREST sync. `user_id` defaults to `auth.uid()`; without an
authenticated session, RLS rejects writes and the app stays in offline mode.

## Verify RLS against a real project

The repository includes a transactional RLS test that creates two synthetic
JWT subjects and asserts that one cannot read, update, or delete the other's
rows:

```bash
export SUPABASE_DB_URL="postgresql://postgres:...@db.<project>.supabase.co:5432/postgres"
./supabase/verify_rls.sh
```

Expected output: `RLS verification passed.` The script rolls back all test
rows. It requires a real database connection; it is intentionally not part of
the offline unit test suite.

## CI

GitHub Actions runs `flutter analyze`, unit tests, and Linux integration tests.
The RLS script is not run in CI because it needs project credentials; add it as
a protected deployment step or a scheduled job with repository secrets.
