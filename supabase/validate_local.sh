#!/usr/bin/env bash
# Applies every migration and the RLS suite to a throwaway Postgres container.
#
# This emulates the pieces of Supabase the schema depends on:
#   - auth.uid() reading request.jwt.claims
#   - authenticated / anon roles
#
# Usage: ./supabase/validate_local.sh
# Requires Docker. No production credentials are used.
set -euo pipefail

IMAGE=${POSTGRES_IMAGE:-postgres:16-alpine}
CONTAINER=finsight-supabase-validate
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
docker run -d --name "$CONTAINER" \
  -e POSTGRES_PASSWORD=postgres \
  -v "$SCRIPT_DIR:/supabase:ro" \
  "$IMAGE" >/dev/null

cleanup() { docker rm -f "$CONTAINER" >/dev/null 2>&1 || true; }
trap cleanup EXIT

for _ in $(seq 1 60); do
  if docker exec "$CONTAINER" pg_isready -U postgres >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

docker exec -i "$CONTAINER" psql -U postgres -v ON_ERROR_STOP=1 <<'SQL' >/dev/null
create schema if not exists auth;
create or replace function auth.uid()
returns uuid
language sql
stable
as $$
  select coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub',
    ''
  )::uuid;
$$;
create role authenticated nologin;
create role anon nologin;
grant usage on schema auth to authenticated, anon;
SQL

for migration in 0001_init.sql 0002_tombstones.sql 0003_budgets.sql \
  0004_wallet_ids.sql 0005_receivables.sql 0006_definitions_sync.sql \
  0007_savings_goals.sql 0008_receipts.sql; do
  echo "Applying $migration"
  docker exec -i "$CONTAINER" psql -U postgres -v ON_ERROR_STOP=1 \
    -f "/supabase/migrations/$migration" >/dev/null
done

echo "Running RLS tests"
docker exec -i "$CONTAINER" psql -U postgres -v ON_ERROR_STOP=1 \
  -f /supabase/tests/rls_test.sql >/dev/null

TABLES=$(docker exec -i "$CONTAINER" psql -U postgres -At -c \
  "select count(*) from pg_tables where schemaname='public' and tablename in
   ('transactions','debts','budgets','receivables','categories',
    'scheduled_payments','wallets','wallet_transfers');")

if [ "$TABLES" -ne 8 ]; then
  echo "Expected 8 synced tables, found $TABLES" >&2
  exit 1
fi

echo "All migrations applied and RLS verification passed."
