#!/bin/sh
# Test runner — executes all test files and reports overall status
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOTAL_SUITES=0
PASSED_SUITES=0
FAILED_SUITES=0

printf '╔══════════════════════════════════════════╗\n'
printf '║   claude-project-status test suite       ║\n'
printf '╚══════════════════════════════════════════╝\n'

for test_file in "$SCRIPT_DIR"/test_*.sh; do
    [ -f "$test_file" ] || continue
    TOTAL_SUITES=$((TOTAL_SUITES + 1))
    test_name=$(basename "$test_file" .sh)

    printf '\n── %s ──\n' "$test_name"

    if sh "$test_file"; then
        PASSED_SUITES=$((PASSED_SUITES + 1))
    else
        FAILED_SUITES=$((FAILED_SUITES + 1))
        printf '  ^^^ SUITE FAILED ^^^\n'
    fi
done

printf '\n══════════════════════════════════════════\n'
printf 'Suites: %d passed, %d failed, %d total\n' "$PASSED_SUITES" "$FAILED_SUITES" "$TOTAL_SUITES"
printf '══════════════════════════════════════════\n'

if [ "$FAILED_SUITES" -gt 0 ]; then
    exit 1
fi

printf '\nAll tests passed!\n'
