#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${SUPABASE_USER_ID:-}" ]]; then
  echo "SUPABASE_USER_ID is required." >&2
  echo "Example: SUPABASE_USER_ID=00000000-0000-0000-0000-000000000000 ./scripts/seed-assets.sh" >&2
  exit 1
fi

if [[ -z "${SUPABASE_DB_URL:-}" ]]; then
  echo "SUPABASE_DB_URL is required." >&2
  echo "Example: SUPABASE_DB_URL=postgresql://user:pass@db.host:5432/postgres" >&2
  exit 1
fi

PSQL_BIN="${PSQL_BIN:-}"

if [[ -z "${PSQL_BIN}" ]]; then
  if command -v psql >/dev/null 2>&1; then
    PSQL_BIN="psql"
  elif [[ -x "/opt/homebrew/opt/libpq/bin/psql" ]]; then
    PSQL_BIN="/opt/homebrew/opt/libpq/bin/psql"
  else
    echo "psql not found. Install libpq or set PSQL_BIN." >&2
    exit 1
  fi
fi

"${PSQL_BIN}" "${SUPABASE_DB_URL}" <<SQL
select set_config('request.jwt.claim.sub', '${SUPABASE_USER_ID}', true);
\i supabase/seed/001_assets.sql
SQL
