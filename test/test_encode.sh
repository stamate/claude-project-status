#!/bin/sh
# Tests for path encoding
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CPS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

. "$CPS_ROOT/lib/encode.sh"

PASS=0
FAIL=0
TOTAL=0

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    TOTAL=$((TOTAL + 1))
    if [ "$expected" = "$actual" ]; then
        printf '  PASS: %s\n' "$desc"
        PASS=$((PASS + 1))
    else
        printf '  FAIL: %s\n' "$desc"
        printf '    expected: [%s]\n' "$expected"
        printf '    actual:   [%s]\n' "$actual"
        FAIL=$((FAIL + 1))
    fi
}

printf '\n=== Encode Tests ===\n'

# Test against known entries in ~/.claude/projects/
assert_eq "basic path" \
    "-Users-c-lab" \
    "$(_claude_encode_path "/Users/c/lab")"

assert_eq "project with hyphens preserved" \
    "-Users-c-lab-claude-project-status" \
    "$(_claude_encode_path "/Users/c/lab/claude-project-status")"

assert_eq "path with dots" \
    "-Users-c--ssh-writing" \
    "$(_claude_encode_path "/Users/c/.ssh-writing")"

assert_eq "path with underscores" \
    "-Users-c-lab-claude-session-manager" \
    "$(_claude_encode_path "/Users/c/lab/claude_session_manager")"

assert_eq "nested path with slashes" \
    "-Users-c-lab-CLARA-date-sintetice" \
    "$(_claude_encode_path "/Users/c/lab/CLARA/date-sintetice")"

assert_eq "deep nested path" \
    "-Users-c-lab-acorai-grants" \
    "$(_claude_encode_path "/Users/c/lab/acorai/grants")"

printf '\n=== Results: %d/%d passed ===\n' "$PASS" "$TOTAL"
[ "$FAIL" -eq 0 ] || exit 1
