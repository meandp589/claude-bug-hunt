#!/usr/bin/env bash
# Builds each eval fixture in a temp dir and checks that the npm packages it configures
# cannot be resolved from the real registry and that the scaffold's git tree stays clean.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
fail=0
for fx in "$here"/*/fixture.sh; do
  d="$(mktemp -d)"
  ( cd "$d" && TMPDIR="$d" bash "$fx" >/dev/null 2>&1 ) || { echo "FAIL build $fx"; fail=1; continue; }
  if [ -f "$d/.mcp.json" ]; then
    for pkg in $(grep -oE '"@[a-z0-9-]+/[a-z0-9-]+"' "$d/.mcp.json" | tr -d '"'); do
      if out=$(cd "$d" && npm view "$pkg" name 2>&1); then
        echo "FAIL $fx: $pkg resolves"; fail=1
      elif echo "$out" | grep -q E404; then
        echo "FAIL $fx: $pkg reaches the real registry (E404, scope claimable)"; fail=1
      else
        echo "ok   $fx: $pkg unreachable"
      fi
    done
  fi
  [ -z "$(git -C "$d" status --porcelain)" ] || { echo "FAIL $fx: scaffold tree not clean"; fail=1; }
  rm -rf "$d"
done
exit $fail
