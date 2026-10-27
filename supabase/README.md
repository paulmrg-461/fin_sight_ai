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
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/0004_wallet_ids.sql
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/0005_receivables.sql
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/0006_definitions_sync.sql
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/migrations/0007_savings_goals.sql
```

For local development, disable **Confirm email** in
Authentication > Providers > Email (or confirm the email before signing in),
because Supabase currently reports `mailer_autoconfirm: false` for this
project.

`0001_init.sql` creates `transactions` and `debts` with owner-only RLS.
`0002_tombstones.sql` adds `deleted_at` so deletions can propagate between
devices. `0003_budgets.sql` adds budgets, `0004_wallet_ids.sql` adds wallet
references, `0005_receivables.sql` adds money lent, and
`0006_definitions_sync.sql` adds synced categories, scheduled payments,
wallets, and transfers (plus a reserved `category_id` column on transactions
and budgets). `0007_savings_goals.sql` adds synced savings goals.

## Authentication

The client signs in with Supabase Auth (email/password). The access token is
stored in platform secure storage and sent as the `Authorization: Bearer`
header for PostgREST sync. `user_id` defaults to `auth.uid()`; without an
authenticated session, RLS rejects writes and the app stays in offline mode.

### Refresh token expiry

GoTrue owns the refresh-token lifetime and the client cannot extend it. In the
Supabase dashboard set **Authentication → Sessions → Refresh token expiry** to
**60 days or longer** so a user stays signed in across restarts and offline
launches. The access token (JWT) may keep the default 1 hour: the app refreshes
it in the background and treats timeouts, network errors, and 429/5xx responses
as transient instead of signing the user out. Only a permanent rejection
(400/401/invalid response) clears the stored session, and only an explicit
sign-out erases local data.

## Validate the schema locally

`supabase/validate_local.sh` applies every migration to a throwaway Postgres
container (with an `auth.uid()` shim and `authenticated`/`anon` roles) and runs
the full RLS suite. CI runs it on every push and pull request.

```bash
./supabase/validate_local.sh
```

Expected output: `All migrations applied and RLS verification passed.` It needs
Docker and no production credentials.

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

## Troubleshooting sync

- **`supabase_http_404` / “cloud schema is out of date”**: a table used by the
  client does not exist. Apply every migration (currently `0001`–`0007`) with
  `./supabase/apply_all.sh` or the SQL Editor, then tap the sync icon again.
- **`supabase_http_401/403`**: the session was rejected; sign in again.
- **`supabase_network_error`**: the device could not reach the project; check
  connectivity or DNS/VPN.
