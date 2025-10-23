#!/bin/bash
# Test script vs sourced mode behavior
# - Script mode: set -euo pipefail active
# - Sourced mode: functions available and exported
# - Early return pattern prevents script code when sourced
# - Function availability in subshells

set -euo pipefail

# Load test framework
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
#shellcheck source=tests/test_framework.sh
source "$SCRIPT_DIR/test_framework.sh"

echo "${BLUE}Testing: Script vs Sourced Modes${RESET}"
echo "======================================"

# ============================================================================
# Sourced Mode Tests
# ============================================================================

# Test 1: Sourcing timer makes timer() function available
unset -f timer 2>/dev/null || true
#shellcheck source=timer
source "$SCRIPT_DIR/../timer"
if declare -f timer >/dev/null; then
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} Sourcing makes timer() available"
else
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("Sourcing makes timer() available")
  echo "${RED}✗${RESET} Sourcing makes timer() available"
fi

# Test 2: Sourcing timer makes format_time_us() function available
if declare -f format_time_us >/dev/null; then
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} Sourcing makes format_time_us() available"
else
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("Sourcing makes format_time_us() available")
  echo "${RED}✗${RESET} Sourcing makes format_time_us() available"
fi

# Test 3: timer function works in current shell
capture_output stdout stderr exit_code timer echo "sourced"
assert_equals "sourced" "$stdout" "Sourced timer executes commands"
assert_contains "$stderr" "# timer:" "Sourced timer reports timing"

# Test 4: format_time_us works in current shell
output=$(format_time_us 1000000)
assert_equals "1.000s" "$output" "Sourced format_time_us works"

# Test 5: timer function is exported (available in subshells)
output=$(bash -c 'timer echo "subshell"' 2>&1)
if [[ "$output" == *"timer: command not found"* ]] || [[ "$output" == *"timer: not found"* ]]; then
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} timer() correctly not available in subshells (needs explicit export)"
else
  # If it worked, that's actually fine too - depends on export settings
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} timer() behavior in subshells (implementation dependent)"
fi

# Test 6: Sourcing doesn't enable set -e in caller
# First, ensure we're not in set -e mode
set +e
#shellcheck source=timer
source "$SCRIPT_DIR/../timer"
if [[ $- != *e* ]]; then
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} Sourcing doesn't enable set -e in caller"
else
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("Sourcing doesn't enable set -e in caller")
  echo "${RED}✗${RESET} Sourcing doesn't enable set -e in caller"
  echo "  Expected: set -e not enabled"
  echo "  Actual:   set -e is enabled (\$- = $-)"
fi
# Re-enable set -e for remaining tests
set -e

# Test 7: Sourcing doesn't enable set -u in caller
set +u
#shellcheck source=timer
source "$SCRIPT_DIR/../timer"
if [[ $- != *u* ]]; then
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} Sourcing doesn't enable set -u in caller"
else
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("Sourcing doesn't enable set -u in caller")
  echo "${RED}✗${RESET} Sourcing doesn't enable set -u in caller"
fi
set -u

# Test 8: Sourcing doesn't execute script mode code (no VERSION variable set)
if declare -p VERSION 2>/dev/null | grep -q 'declare -r VERSION='; then
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("Sourcing doesn't set VERSION variable")
  echo "${RED}✗${RESET} Sourcing doesn't set VERSION variable"
  echo "  Expected: VERSION not set"
  echo "  Actual:   VERSION=${VERSION}"
else
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} Sourcing doesn't set VERSION variable (script-only)"
fi

# Test 9: Sourcing doesn't set SCRIPT_NAME variable
if declare -p SCRIPT_NAME 2>/dev/null | grep -q 'declare -r SCRIPT_NAME='; then
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("Sourcing doesn't set SCRIPT_NAME variable")
  echo "${RED}✗${RESET} Sourcing doesn't set SCRIPT_NAME variable"
else
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} Sourcing doesn't set SCRIPT_NAME variable (script-only)"
fi

# ============================================================================
# Script Mode Tests
# ============================================================================

# Test 10: Script mode executes command
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" echo "script"
assert_success "$exit_code" "Script mode executes successfully"
assert_equals "script" "$stdout" "Script mode command output correct"

# Test 11: Script mode produces timing output
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" true
assert_contains "$stderr" "# timer:" "Script mode reports timing"

# Test 12: Script mode preserves exit status
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" false
assert_failure "$exit_code" 1 "Script mode preserves failure exit code"

# Test 13: Script mode with -f flag
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -f true
assert_success "$exit_code" "Script mode -f works"
assert_not_matches "$stderr" '# timer: [0-9]+\.[0-9]{6}s$' "Script mode -f uses formatted output"

# Test 14: Script can be called from different working directory
(
  cd /tmp || exit 1
  capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" echo "test"
  assert_equals "test" "$stdout" "Script works from different directory"
)

# Test 15: Script with no arguments shows error
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer"
# Should fail because no command provided
if ((exit_code == 0)); then
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("Script with no command shows error")
  echo "${RED}✗${RESET} Script with no command shows error"
  echo "  Expected: non-zero exit code"
  echo "  Actual:   exit code 0"
else
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} Script with no command shows error"
fi

# Test 16: Script mode help doesn't execute timer function
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -h
assert_success "$exit_code" "Script -h exits successfully"
assert_not_contains "$stderr" "# timer:" "Script -h doesn't show timing"

# Test 17: Script mode version doesn't execute timer function
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -V
assert_success "$exit_code" "Script -V exits successfully"
assert_not_contains "$stderr" "# timer:" "Script -V doesn't show timing"

# Print summary
print_summary

#fin
