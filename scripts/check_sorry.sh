#!/usr/bin/env bash
# Fail on any `sorry` under LeanToolchain/, except in files listed (one path per
# line, repo-relative) in scripts/sorry_allowlist.txt. Lines starting with `#` are ignored.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ALLOW="$ROOT/scripts/sorry_allowlist.txt"

hits=()
while IFS= read -r line; do
  [[ -n "$line" ]] && hits+=("$line")
done < <(grep -RIn --include='*.lean' -E '\bsorry\b' LeanToolchain 2>/dev/null || true)

if ((${#hits[@]} == 0)); then
  exit 0
fi

is_allowed_file() {
  local rel="$1"
  [[ -f "$ALLOW" ]] || return 1
  awk -v f="$rel" '
    /^#/ { next }
    NF == 0 { next }
    $0 == f { found = 1 }
    END { exit found ? 0 : 1 }
  ' "$ALLOW"
}

bad=()
for hit in "${hits[@]}"; do
  f="${hit%%:*}"
  rel="${f#./}"
  if is_allowed_file "$rel"; then
    continue
  fi
  bad+=("$hit")
done

if ((${#bad[@]} > 0)); then
  echo "Disallowed 'sorry' in Lean sources (add whole-file waiver to scripts/sorry_allowlist.txt if intentional):" >&2
  printf '%s\n' "${bad[@]}" >&2
  exit 1
fi
