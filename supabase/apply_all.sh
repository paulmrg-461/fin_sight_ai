#!/usr/bin/env bash
# Applies all FinSight AI migrations to a Supabase Postgres database.
#
# Usage (prefer a session pooler connection string from Supabase Dashboard):
#   SUPABASE_DB_URL="postgresql://postgres:...@db.<project>.supabase.co:5432/postgres" \
#     ./supabase/apply_all.sh
set -euo pipefail

: "${SUPABASE_DB_URL:?Set SUPABASE_DB_URL to a Postgres connection string}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for migration in 0001_init.sql 0002_tombstones.sql 0003_budgets.sql 0004_wallet_ids.sql 0005_receivables.sql 0006_definitions_sync.sql 0007_savings_goals.sql; do
  echo "Applying $migration..."
  psql "$SUPABASE_DB_URL" \
    -v ON_ERROR_STOP=1 \
    -f "$SCRIPT_DIR/migrations/$migration"
done

echo "All migrations applied."
