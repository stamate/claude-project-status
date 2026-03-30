#!/bin/sh
# Tests for the formatting module
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CPS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

. "$CPS_ROOT/lib/format.sh"

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

assert_contains() {
    local desc="$1" needle="$2" haystack="$3"
    TOTAL=$((TOTAL + 1))
    case "$haystack" in
        *"$needle"*)
            printf '  PASS: %s\n' "$desc"
            PASS=$((PASS + 1))
            ;;
        *)
            printf '  FAIL: %s (contains check)\n' "$desc"
            printf '    expected to contain: [%s]\n' "$needle"
            printf '    actual:              [%s]\n' "$haystack"
            FAIL=$((FAIL + 1))
            ;;
    esac
}

printf '\n=== Format Tests ===\n'

# Test 1: Plain text with flags
CLAUDE_PROMPT_COLOR=0
export CLAUDE_PROMPT_COLOR
_claude_format_segment "myproject" "md,local"
assert_eq "plain with flags" "[claude:myproject md,local] " "$_CLAUDE_PS_CACHED_OUTPUT"

# Test 2: Plain text without flags
_claude_format_segment "myproject" ""
assert_eq "plain without flags" "[claude:myproject] " "$_CLAUDE_PS_CACHED_OUTPUT"

# Test 3: Plain text with single flag
_claude_format_segment "thesis" "md"
assert_eq "plain single flag" "[claude:thesis md] " "$_CLAUDE_PS_CACHED_OUTPUT"

# Test 4: Custom format
CLAUDE_PROMPT_FORMAT="(%n|%f)"
export CLAUDE_PROMPT_FORMAT
_CLAUDE_PS_ROOT="/fake/path"
_claude_format_segment "myproject" "md,cfg"
assert_contains "custom format: name" "myproject" "$_CLAUDE_PS_CACHED_OUTPUT"
assert_contains "custom format: flags" "md,cfg" "$_CLAUDE_PS_CACHED_OUTPUT"
unset CLAUDE_PROMPT_FORMAT

# Test 5: All three flags
CLAUDE_PROMPT_COLOR=0
_claude_format_segment "full" "md,cfg,local"
assert_eq "all flags" "[claude:full md,cfg,local] " "$_CLAUDE_PS_CACHED_OUTPUT"

# Test 6: Project name with hyphens
_claude_format_segment "my-cool-project" "md"
assert_eq "hyphenated name" "[claude:my-cool-project md] " "$_CLAUDE_PS_CACHED_OUTPUT"

unset CLAUDE_PROMPT_COLOR

printf '\n=== Results: %d/%d passed ===\n' "$PASS" "$TOTAL"
[ "$FAIL" -eq 0 ] || exit 1
