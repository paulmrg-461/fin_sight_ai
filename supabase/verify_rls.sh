#!/usr/bin/env bash
# Verifies Row Level Security against a real Supabase database.
#
# Usage:
#   SUPABASE_DB_URL="postgresql://postgres:...@db.<project>.supabase.co:5432/postgres" \
#     ./supabase/verify_rls.sh
set -euo pipefail

: "${SUPABASE_DB_URL:?Set SUPABASE_DB_URL to a Postgres connection string}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

psql "$SUPABASE_DB_URL" \
  -v ON_ERROR_STOP=1 \
  -f "$SCRIPT_DIR/tests/rls_test.sql"

echo "RLS verification passed."
