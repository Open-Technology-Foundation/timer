#!/bin/bash
# Pure Bash test framework for timer
# Zero external dependencies - no bats, no external assertion libraries
# Provides: assertion functions, test tracking, output capture, reporting

set -euo pipefail

# Test result tracking
declare -i TESTS_PASSED=0 TESTS_FAILED=0 TESTS_TOTAL=0
declare -a FAILED_TESTS=()

# Color codes for output (if terminal supports it)
if [[ -t 1 ]]; then
  declare -r RED=$'\033[0;31m'
  declare -r GREEN=$'\033[0;32m'
  declare -r YELLOW=$'\033[0;33m'
  declare -r BLUE=$'\033[0;34m'
  declare -r RESET=$'\033[0m'
else
  declare -r RED='' GREEN='' YELLOW='' BLUE='' RESET=''
fi

# Capture command output (stdout and stderr separately)
# Usage: capture_output stdout stderr exit_code timer echo "hello"
# Example: capture_output out err code timer echo "hello"
# NOTE: Variables are set as global in caller's scope
capture_output() {
  # Variable names from caller
  local -- stdout_var=$1 stderr_var=$2 exit_var=$3
  shift 3

  local -- stdout_file stderr_file
  stdout_file=$(mktemp)
  stderr_file=$(mktemp)

  local -i cmd_exit_code=0
  set +u  # Temporarily disable unset variable checking for command execution
  "$@" >"$stdout_file" 2>"$stderr_file" || cmd_exit_code=$?
  set -u  # Re-enable

  # Read files into variables
  local -- stdout_content stderr_content
  stdout_content=$(<"$stdout_file")
  stderr_content=$(<"$stderr_file")

  # Clean up temp files
  rm -f "$stdout_file" "$stderr_file"

  # Return values via eval - use printf %q for safe quoting
  eval "$(printf '%s=%q' "$stdout_var" "$stdout_content")"
  eval "$(printf '%s=%q' "$stderr_var" "$stderr_content")"
  eval "$(printf '%s=%q' "$exit_var" "$cmd_exit_code")"
}

# Assert that two values are equal
# Usage: assert_equals <expected> <actual> <test_name>
assert_equals() {
  local -- expected=$1 actual=$2 test_name=$3

  TESTS_TOTAL+=1

  if [[ "$expected" == "$actual" ]]; then
    TESTS_PASSED+=1
    echo "${GREEN}✓${RESET} $test_name"
    return 0
  else
    TESTS_FAILED+=1
    FAILED_TESTS+=("$test_name")
    echo "${RED}✗${RESET} $test_name"
    echo "  Expected: ${YELLOW}${expected@Q}${RESET}"
    echo "  Actual:   ${YELLOW}${actual@Q}${RESET}"
    return 1
  fi
}

# Assert that exit code indicates success (0)
# Usage: assert_success <exit_code> <test_name>
assert_success() {
  local -i exit_code=$1
  local -- test_name=$2

  TESTS_TOTAL+=1

  if ((exit_code == 0)); then
    TESTS_PASSED+=1
    echo "${GREEN}✓${RESET} $test_name"
    return 0
  else
    TESTS_FAILED+=1
    FAILED_TESTS+=("$test_name")
    echo "${RED}✗${RESET} $test_name"
    echo "  Expected: exit code 0"
    echo "  Actual:   exit code $exit_code"
    return 1
  fi
}

# Assert that exit code indicates failure (non-zero)
# Usage: assert_failure <exit_code> <expected_code> <test_name>
assert_failure() {
  local -i exit_code=$1 expected_code=$2
  local -- test_name=$3

  TESTS_TOTAL+=1

  if ((exit_code == expected_code)); then
    TESTS_PASSED+=1
    echo "${GREEN}✓${RESET} $test_name"
    return 0
  else
    TESTS_FAILED+=1
    FAILED_TESTS+=("$test_name")
    echo "${RED}✗${RESET} $test_name"
    echo "  Expected: exit code $expected_code"
    echo "  Actual:   exit code $exit_code"
    return 1
  fi
}

# Assert that string contains substring
# Usage: assert_contains <haystack> <needle> <test_name>
assert_contains() {
  local -- haystack=$1 needle=$2 test_name=$3

  TESTS_TOTAL+=1

  if [[ "$haystack" == *"$needle"* ]]; then
    TESTS_PASSED+=1
    echo "${GREEN}✓${RESET} $test_name"
    return 0
  else
    TESTS_FAILED+=1
    FAILED_TESTS+=("$test_name")
    echo "${RED}✗${RESET} $test_name"
    echo "  Expected to contain: ${YELLOW}${needle@Q}${RESET}"
    echo "  Actual string:       ${YELLOW}${haystack@Q}${RESET}"
    return 1
  fi
}

# Assert that string matches regex pattern
# Usage: assert_matches <string> <pattern> <test_name>
assert_matches() {
  local -- string=$1 pattern=$2 test_name=$3

  TESTS_TOTAL+=1

  if [[ "$string" =~ $pattern ]]; then
    TESTS_PASSED+=1
    echo "${GREEN}✓${RESET} $test_name"
    return 0
  else
    TESTS_FAILED+=1
    FAILED_TESTS+=("$test_name")
    echo "${RED}✗${RESET} $test_name"
    echo "  Expected to match: ${YELLOW}${pattern@Q}${RESET}"
    echo "  Actual string:     ${YELLOW}${string@Q}${RESET}"
    return 1
  fi
}

# Assert that string does not contain substring
# Usage: assert_not_contains <haystack> <needle> <test_name>
assert_not_contains() {
  local -- haystack=$1 needle=$2 test_name=$3

  TESTS_TOTAL+=1

  if [[ "$haystack" != *"$needle"* ]]; then
    TESTS_PASSED+=1
    echo "${GREEN}✓${RESET} $test_name"
    return 0
  else
    TESTS_FAILED+=1
    FAILED_TESTS+=("$test_name")
    echo "${RED}✗${RESET} $test_name"
    echo "  Expected NOT to contain: ${YELLOW}${needle@Q}${RESET}"
    echo "  Actual string:           ${YELLOW}${haystack@Q}${RESET}"
    return 1
  fi
}

# Assert that string does not match regex pattern
# Usage: assert_not_matches <string> <pattern> <test_name>
assert_not_matches() {
  local -- string=$1 pattern=$2 test_name=$3

  TESTS_TOTAL+=1

  if [[ ! "$string" =~ $pattern ]]; then
    TESTS_PASSED+=1
    echo "${GREEN}✓${RESET} $test_name"
    return 0
  else
    TESTS_FAILED+=1
    FAILED_TESTS+=("$test_name")
    echo "${RED}✗${RESET} $test_name"
    echo "  Expected NOT to match: ${YELLOW}${pattern@Q}${RESET}"
    echo "  Actual string:         ${YELLOW}${string@Q}${RESET}"
    return 1
  fi
}

# Print test summary
print_summary() {
  echo ""
  echo "================================"
  if ((TESTS_FAILED == 0)); then
    echo "${GREEN}All tests passed!${RESET}"
  else
    echo "${RED}Some tests failed:${RESET}"
    for test in "${FAILED_TESTS[@]}"; do
      echo "  ${RED}✗${RESET} $test"
    done
  fi
  echo "--------------------------------"
  echo "Total:  $TESTS_TOTAL"
  echo "Passed: ${GREEN}$TESTS_PASSED${RESET}"
  echo "Failed: ${RED}$TESTS_FAILED${RESET}"
  echo "================================"

  return "$TESTS_FAILED"
}

# Reset test counters (useful when running multiple test files)
reset_counters() {
  TESTS_PASSED=0
  TESTS_FAILED=0
  TESTS_TOTAL=0
  FAILED_TESTS=()
}

#fin
