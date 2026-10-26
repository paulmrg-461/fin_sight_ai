#!/usr/bin/env bash
# Runs the app with all credentials from the local, untracked .env file.
# Usage: ./tool/run_dev.sh [extra flutter args]
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if [[ ! -f .env ]]; then
  echo "Missing .env. Copy example.env to .env and fill in your credentials." >&2
  exit 1
fi

# --dart-define-from-file accepts only comments and KEY=value lines. Catch
# pasted shell commands early instead of silently running without credentials.
if grep -Ev '^[[:space:]]*(#|$)' .env \
  | grep -qvE '^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*='; then
  echo "Invalid .env: use only comments and KEY=value lines." >&2
  grep -Env '^[[:space:]]*(#|$)' .env \
    | grep -vE '^[0-9]+:[[:space:]]*[A-Za-z_][A-Za-z0-9_]*=' >&2 || true
  exit 1
fi

exec flutter run --dart-define-from-file=.env "$@"
