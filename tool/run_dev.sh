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

exec flutter run --dart-define-from-file=.env "$@"
