#!/bin/bash
# Test basic timer functionality
# - Command execution and timing
# - Exit status preservation
# - Output separation (stdout vs stderr)
# - Output format validation

set -euo pipefail

# Load test framework
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
#shellcheck source=tests/test_framework.sh
source "$SCRIPT_DIR/test_framework.sh"

# Load timer as a sourced function
#shellcheck source=timer
source "$SCRIPT_DIR/../timer"

echo "${BLUE}Testing: Basic Functionality${RESET}"
echo "======================================"

# Test 1: Timer executes command successfully
capture_output stdout stderr exit_code timer echo "hello world"
assert_success "$exit_code" "Timer executes command successfully"
assert_equals "hello world" "$stdout" "Command stdout is preserved"
assert_contains "$stderr" "# timer:" "Timing info appears in stderr"

# Test 2: Timer reports timing in correct format (seconds with 6 decimals)
capture_output stdout stderr exit_code timer true
assert_matches "$stderr" '# timer: [0-9]+\.[0-9]{6}s' "Timing format is X.XXXXXXs"

# Test 3: Exit status preservation - success
capture_output stdout stderr exit_code timer true
assert_success "$exit_code" "Successful command returns 0"

# Test 4: Exit status preservation - failure
capture_output stdout stderr exit_code timer false
assert_failure "$exit_code" 1 "Failed command returns 1"

# Test 5: Exit status preservation - specific exit code
capture_output stdout stderr exit_code timer bash -c 'exit 42'
assert_failure "$exit_code" 42 "Command with exit 42 returns 42"

# Test 6: Command output goes to stdout only
capture_output stdout stderr exit_code timer echo "test output"
assert_equals "test output" "$stdout" "Command stdout is captured"
assert_not_contains "$stdout" "# timer:" "Timer info not in stdout"

# Test 7: Timer info goes to stderr only
capture_output stdout stderr exit_code timer echo "test"
assert_contains "$stderr" "# timer:" "Timer info in stderr"
assert_not_contains "$stderr" "test" "Command output not in stderr"

# Test 8: Command with both stdout and stderr
capture_output stdout stderr exit_code timer bash -c 'echo "out"; >&2 echo "err"'
assert_equals "out" "$stdout" "Command stdout captured correctly"
assert_contains "$stderr" "err" "Command stderr preserved"
assert_contains "$stderr" "# timer:" "Timer info added to stderr"

# Test 9: Command with multiple arguments
capture_output stdout stderr exit_code timer echo "arg1" "arg2" "arg3"
assert_equals "arg1 arg2 arg3" "$stdout" "Multiple arguments passed correctly"

# Test 10: Command with arguments containing spaces
capture_output stdout stderr exit_code timer echo "hello world"
assert_equals "hello world" "$stdout" "Arguments with spaces handled correctly"

# Test 11: Very short duration command
capture_output stdout stderr exit_code timer true
assert_success "$exit_code" "Very short command executes successfully"
assert_contains "$stderr" "# timer:" "Timer reports for very short commands"

# Test 12: Command that takes measurable time
capture_output stdout stderr exit_code timer sleep 0.01
assert_success "$exit_code" "Sleep command executes successfully"
# Extract the timing value and verify it's >= 0.01 seconds
if [[ "$stderr" =~ timer:\ ([0-9]+\.[0-9]+)s ]]; then
  duration=${BASH_REMATCH[1]}
  # Compare as integers (convert to milliseconds)
  duration_ms=$(printf "%.0f" "$(printf "%.3f" "${duration}e3")")
  if ((duration_ms >= 10)); then
    TESTS_PASSED+=1
    TESTS_TOTAL+=1
    echo "${GREEN}✓${RESET} Sleep 0.01s takes at least 0.01s"
  else
    TESTS_FAILED+=1
    TESTS_TOTAL+=1
    FAILED_TESTS+=("Sleep 0.01s takes at least 0.01s")
    echo "${RED}✗${RESET} Sleep 0.01s takes at least 0.01s"
    echo "  Expected: >= 0.010s"
    echo "  Actual:   ${duration}s"
  fi
else
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("Sleep 0.01s timing format")
  echo "${RED}✗${RESET} Sleep 0.01s timing format"
  echo "  Could not parse timing from: ${stderr@Q}"
fi

# Test 13: Timer output includes newline prefix
capture_output stdout stderr exit_code timer true
assert_matches "$stderr" $'^\n# timer:' "Timer output starts with newline"

# Print summary
print_summary

#fin
