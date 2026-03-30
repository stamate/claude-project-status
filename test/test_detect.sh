#!/bin/sh
# Tests for the core detection algorithm
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CPS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

. "$CPS_ROOT/lib/format.sh"
. "$CPS_ROOT/lib/detect.sh"

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

# Setup: create temp project structures
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Project with .claude/ directory
mkdir -p "$TMPDIR/proj_full/.claude"
printf '{}' > "$TMPDIR/proj_full/.claude/settings.json"
printf '{}' > "$TMPDIR/proj_full/.claude/settings.local.json"
printf '# Test' > "$TMPDIR/proj_full/CLAUDE.md"
mkdir -p "$TMPDIR/proj_full/src/deep/nested"

# Project with only CLAUDE.md
mkdir -p "$TMPDIR/proj_md_only/src"
printf '# Test' > "$TMPDIR/proj_md_only/CLAUDE.md"

# Project with .claude/ but no other files
mkdir -p "$TMPDIR/proj_bare/.claude"

# Non-project directory
mkdir -p "$TMPDIR/not_a_project/src"

printf '\n=== Detection Tests ===\n'

# Test 1: Detect full project from root
_CLAUDE_PS_CACHED_PWD=""
PWD="$TMPDIR/proj_full"
_claude_detect_project
assert_eq "full project: root detected" "$TMPDIR/proj_full" "$_CLAUDE_PS_ROOT"
assert_eq "full project: name" "proj_full" "$_CLAUDE_PS_NAME"
assert_eq "full project: has md,cfg,local flags" "md,cfg,local" "$_CLAUDE_PS_FLAGS"

# Test 2: Detect from nested subdirectory
_CLAUDE_PS_CACHED_PWD=""
PWD="$TMPDIR/proj_full/src/deep/nested"
_claude_detect_project
assert_eq "nested dir: root detected" "$TMPDIR/proj_full" "$_CLAUDE_PS_ROOT"
assert_eq "nested dir: name" "proj_full" "$_CLAUDE_PS_NAME"

# Test 3: Detect CLAUDE.md-only project
_CLAUDE_PS_CACHED_PWD=""
PWD="$TMPDIR/proj_md_only"
_claude_detect_project
assert_eq "md-only project: root detected" "$TMPDIR/proj_md_only" "$_CLAUDE_PS_ROOT"
assert_eq "md-only project: flags" "md" "$_CLAUDE_PS_FLAGS"

# Test 4: Detect from subdirectory of CLAUDE.md project
_CLAUDE_PS_CACHED_PWD=""
PWD="$TMPDIR/proj_md_only/src"
_claude_detect_project
assert_eq "md-only nested: root detected" "$TMPDIR/proj_md_only" "$_CLAUDE_PS_ROOT"

# Test 5: Bare .claude/ directory (no files inside)
_CLAUDE_PS_CACHED_PWD=""
PWD="$TMPDIR/proj_bare"
_claude_detect_project
assert_eq "bare .claude/: root detected" "$TMPDIR/proj_bare" "$_CLAUDE_PS_ROOT"
assert_eq "bare .claude/: no flags" "" "$_CLAUDE_PS_FLAGS"

# Test 6: Non-project directory
_CLAUDE_PS_CACHED_PWD=""
PWD="$TMPDIR/not_a_project/src"
_claude_detect_project
assert_eq "non-project: no root" "" "$_CLAUDE_PS_ROOT"
assert_eq "non-project: empty output" "" "$_CLAUDE_PS_CACHED_OUTPUT"

# Test 7: Cache hit (same PWD)
_CLAUDE_PS_CACHED_PWD="$TMPDIR/proj_full"
_CLAUDE_PS_ROOT="$TMPDIR/proj_full"
_CLAUDE_PS_NAME="proj_full"
_CLAUDE_PS_FLAGS="md,cfg,local"
_CLAUDE_PS_CACHED_OUTPUT="cached_value"
PWD="$TMPDIR/proj_full"
_claude_detect_project
assert_eq "cache hit: preserves output" "cached_value" "$_CLAUDE_PS_CACHED_OUTPUT"

# Test 8: CLAUDE_PROMPT_DISABLE
_CLAUDE_PS_CACHED_PWD=""
CLAUDE_PROMPT_DISABLE=1
PWD="$TMPDIR/proj_full"
_claude_detect_project
assert_eq "disabled: empty output" "" "$_CLAUDE_PS_CACHED_OUTPUT"
assert_eq "disabled: no root" "" "$_CLAUDE_PS_ROOT"
unset CLAUDE_PROMPT_DISABLE

# Test 9: CLAUDE_PROJECT_ROOT override
_CLAUDE_PS_CACHED_PWD=""
CLAUDE_PROJECT_ROOT="$TMPDIR/proj_md_only"
PWD="$TMPDIR/not_a_project"
_claude_detect_project
assert_eq "override root: uses env var" "$TMPDIR/proj_md_only" "$_CLAUDE_PS_ROOT"
assert_eq "override root: correct name" "proj_md_only" "$_CLAUDE_PS_NAME"
unset CLAUDE_PROJECT_ROOT

# Test 10: $HOME exclusion
_CLAUDE_PS_CACHED_PWD=""
# Simulate: create .claude in a fake HOME
FAKE_HOME="$TMPDIR/fakehome"
mkdir -p "$FAKE_HOME/.claude"
OLD_HOME="$HOME"
HOME="$FAKE_HOME"
PWD="$FAKE_HOME"
_claude_detect_project
assert_eq "HOME exclusion: no root" "" "$_CLAUDE_PS_ROOT"
HOME="$OLD_HOME"

# Test 11: DISABLE → re-enable cache invalidation
_CLAUDE_PS_CACHED_PWD=""
PWD="$TMPDIR/proj_full"
_claude_detect_project
assert_eq "disable/re-enable: initial detect" "proj_full" "$_CLAUDE_PS_NAME"
CLAUDE_PROMPT_DISABLE=1
_claude_detect_project
assert_eq "disable/re-enable: disabled clears root" "" "$_CLAUDE_PS_ROOT"
unset CLAUDE_PROMPT_DISABLE
_claude_detect_project
assert_eq "disable/re-enable: re-enabled detects" "proj_full" "$_CLAUDE_PS_NAME"

# Test 12: Nested projects — closest ancestor wins
mkdir -p "$TMPDIR/parent_proj/child_proj/.claude"
printf '# parent' > "$TMPDIR/parent_proj/CLAUDE.md"
printf '# child' > "$TMPDIR/parent_proj/child_proj/CLAUDE.md"
mkdir -p "$TMPDIR/parent_proj/child_proj/deep"

_CLAUDE_PS_CACHED_PWD=""
PWD="$TMPDIR/parent_proj/child_proj/deep"
_claude_detect_project
assert_eq "nested: detects child from deep" "child_proj" "$_CLAUDE_PS_NAME"

_CLAUDE_PS_CACHED_PWD=""
PWD="$TMPDIR/parent_proj"
_claude_detect_project
assert_eq "nested: detects parent from parent" "parent_proj" "$_CLAUDE_PS_NAME"

# Test 13: Symlink to project
ln -s "$TMPDIR/proj_full" "$TMPDIR/symlinked_proj"
_CLAUDE_PS_CACHED_PWD=""
PWD="$TMPDIR/symlinked_proj"
_claude_detect_project
assert_eq "symlink: detects project" "symlinked_proj" "$_CLAUDE_PS_NAME"

# Test 14: Project name with spaces
mkdir -p "$TMPDIR/my project/.claude"
_CLAUDE_PS_CACHED_PWD=""
PWD="$TMPDIR/my project"
_claude_detect_project
assert_eq "spaces in name: detected" "my project" "$_CLAUDE_PS_NAME"

# Test 15: Cache invalidation on cd (PWD change)
_CLAUDE_PS_CACHED_PWD=""
PWD="$TMPDIR/proj_full"
_claude_detect_project
assert_eq "cache cd: first dir" "proj_full" "$_CLAUDE_PS_NAME"
PWD="$TMPDIR/proj_md_only"
_claude_detect_project
assert_eq "cache cd: second dir" "proj_md_only" "$_CLAUDE_PS_NAME"

# Test 16: .claude/ takes priority over CLAUDE.md at same level
# (both are detected; .claude/ triggers break first in walk-up)
mkdir -p "$TMPDIR/both_markers/.claude"
printf '# test' > "$TMPDIR/both_markers/CLAUDE.md"
_CLAUDE_PS_CACHED_PWD=""
PWD="$TMPDIR/both_markers"
_claude_detect_project
assert_eq "both markers: root detected" "$TMPDIR/both_markers" "$_CLAUDE_PS_ROOT"
assert_eq "both markers: md flag set" "md" "$_CLAUDE_PS_FLAGS"

# Test 17: CLAUDE_PROJECT_ROOT pointing to non-existent dir
# When override is set, walk-up is skipped — treats override as authoritative
_CLAUDE_PS_CACHED_PWD=""
CLAUDE_PROJECT_ROOT="$TMPDIR/nonexistent"
PWD="$TMPDIR/proj_full"
_claude_detect_project
assert_eq "nonexistent override: no detection (override authoritative)" "" "$_CLAUDE_PS_ROOT"
unset CLAUDE_PROJECT_ROOT

printf '\n=== Results: %d/%d passed ===\n' "$PASS" "$TOTAL"
[ "$FAIL" -eq 0 ] || exit 1
