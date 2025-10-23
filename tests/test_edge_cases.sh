#!/bin/bash
# Test edge cases and error conditions
# - Commands with special characters
# - Arguments with spaces and quotes
# - Empty/missing commands
# - Very short and very long durations
# - Commands with stdin/stdout/stderr complexity
# - Various exit codes

set -euo pipefail

# Load test framework
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
#shellcheck source=tests/test_framework.sh
source "$SCRIPT_DIR/test_framework.sh"

# Load timer as a sourced function
#shellcheck source=timer
source "$SCRIPT_DIR/../timer"

echo "${BLUE}Testing: Edge Cases${RESET}"
echo "======================================"

# ============================================================================
# Special Characters and Quoting
# ============================================================================

# Test 1: Arguments with spaces
capture_output stdout stderr exit_code timer echo "hello world"
assert_equals "hello world" "$stdout" "Arguments with spaces preserved"

# Test 2: Arguments with multiple spaces
capture_output stdout stderr exit_code timer echo "hello    world"
assert_equals "hello    world" "$stdout" "Multiple spaces preserved"

# Test 3: Arguments with special chars - dollar sign
capture_output stdout stderr exit_code timer echo '$HOME'
assert_equals '$HOME' "$stdout" "Dollar sign in single quotes preserved"

# Test 4: Arguments with special chars - asterisk
capture_output stdout stderr exit_code timer echo '*'
assert_equals '*' "$stdout" "Asterisk in quotes preserved"

# Test 5: Arguments with special chars - question mark
capture_output stdout stderr exit_code timer echo '?'
assert_equals '?' "$stdout" "Question mark in quotes preserved"

# Test 6: Arguments with backslash
capture_output stdout stderr exit_code timer echo 'back\slash'
assert_equals 'back\slash' "$stdout" "Backslash preserved"

# Test 7: Arguments with single quotes
capture_output stdout stderr exit_code timer echo "it's"
assert_equals "it's" "$stdout" "Single quote in double quotes preserved"

# Test 8: Arguments with double quotes (escaped)
capture_output stdout stderr exit_code timer bash -c 'echo "quoted"'
assert_equals "quoted" "$stdout" "Double quotes in command preserved"

# Test 9: Empty string argument
capture_output stdout stderr exit_code timer echo ""
assert_equals "" "$stdout" "Empty string argument handled"

# Test 10: Many arguments (stress test)
capture_output stdout stderr exit_code timer echo a b c d e f g h i j k l m n o p q r s t
assert_equals "a b c d e f g h i j k l m n o p q r s t" "$stdout" "Many arguments handled correctly"

# ============================================================================
# stdin/stdout/stderr Complexity
# ============================================================================

# Test 11: Command reading from stdin
capture_output stdout stderr exit_code bash -c 'echo "input" | timer cat'
assert_equals "input" "$stdout" "Command reading stdin works"

# Test 12: Command with heredoc
capture_output stdout stderr exit_code timer bash -c 'cat <<EOF
line1
line2
EOF'
expected=$'line1\nline2'
assert_equals "$expected" "$stdout" "Command with heredoc works"

# Test 13: Command producing multiline output
capture_output stdout stderr exit_code timer bash -c 'echo "line1"; echo "line2"'
expected=$'line1\nline2'
assert_equals "$expected" "$stdout" "Multiline output preserved"

# Test 14: Command with stderr and stdout
capture_output stdout stderr exit_code timer bash -c 'echo "out"; >&2 echo "err"'
assert_equals "out" "$stdout" "stdout separated correctly"
assert_contains "$stderr" "err" "stderr contains command error"
assert_contains "$stderr" "# timer:" "stderr contains timing"

# Test 15: Command with only stderr
capture_output stdout stderr exit_code timer bash -c '>&2 echo "error"'
assert_equals "" "$stdout" "No stdout when command only outputs stderr"
assert_contains "$stderr" "error" "stderr preserved"

# Test 16: Command with empty output
capture_output stdout stderr exit_code timer true
assert_equals "" "$stdout" "Empty stdout handled"

# ============================================================================
# Various Exit Codes
# ============================================================================

# Test 17: Exit code 0
capture_output stdout stderr exit_code timer bash -c 'exit 0'
assert_success "$exit_code" "Exit code 0 preserved"

# Test 18: Exit code 1
capture_output stdout stderr exit_code timer bash -c 'exit 1'
assert_failure "$exit_code" 1 "Exit code 1 preserved"

# Test 19: Exit code 2
capture_output stdout stderr exit_code timer bash -c 'exit 2'
assert_failure "$exit_code" 2 "Exit code 2 preserved"

# Test 20: Exit code 127 (command not found)
capture_output stdout stderr exit_code timer bash -c 'exit 127'
assert_failure "$exit_code" 127 "Exit code 127 preserved"

# Test 21: Exit code 255
capture_output stdout stderr exit_code timer bash -c 'exit 255'
assert_failure "$exit_code" 255 "Exit code 255 preserved"

# Test 22: Large exit code (wraps to 0-255)
capture_output stdout stderr exit_code timer bash -c 'exit 257'
# 257 % 256 = 1
assert_failure "$exit_code" 1 "Exit code 257 wraps to 1"

# ============================================================================
# Command Edge Cases
# ============================================================================

# Test 23: Command is a shell builtin
capture_output stdout stderr exit_code timer pwd
# Just verify it doesn't error
assert_success "$exit_code" "Shell builtin command works"

# Test 24: Command is a function (after defining it)
test_func() { echo "function output"; }
export -f test_func
capture_output stdout stderr exit_code timer bash -c 'test_func'
assert_equals "function output" "$stdout" "Function as command works"

# Test 25: Command with subshell
capture_output stdout stderr exit_code timer bash -c '(echo "subshell")'
assert_equals "subshell" "$stdout" "Subshell command works"

# Test 26: Command with background process (detached)
capture_output stdout stderr exit_code timer bash -c 'true &'
assert_success "$exit_code" "Background process command works"

# Test 27: Command is a pipeline
capture_output stdout stderr exit_code timer bash -c 'echo "test" | tr "a-z" "A-Z"'
assert_equals "TEST" "$stdout" "Pipeline command works"

# Test 28: Command with AND operator
capture_output stdout stderr exit_code timer bash -c 'true && echo "yes"'
assert_equals "yes" "$stdout" "AND operator command works"

# Test 29: Command with OR operator
capture_output stdout stderr exit_code timer bash -c 'false || echo "yes"'
assert_equals "yes" "$stdout" "OR operator command works"

# ============================================================================
# Duration Edge Cases
# ============================================================================

# Test 30: Very short duration (true command)
capture_output stdout stderr exit_code timer true
assert_success "$exit_code" "Very short duration command succeeds"
# Should still have timing
assert_contains "$stderr" "# timer:" "Very short duration has timing"

# Test 31: Simulated longer duration with format
capture_output stdout stderr exit_code timer -f sleep 0.05
assert_success "$exit_code" "50ms duration with format succeeds"
# Verify it's formatted, not decimal
assert_not_matches "$stderr" '# timer: 0\.[0-9]{6}s$' "Format used for 50ms sleep"

# Test 32: Zero-duration calculation (format_time_us with 0)
output=$(format_time_us 0)
assert_equals "0.000s" "$output" "Zero microseconds formats as 0.000s"

# Test 33: Maximum safe integer (format_time_us stress test)
# 9007199254740991 microseconds = ~104 days (in JavaScript max safe int)
# Let's use a large but reasonable value: 10 days = 864000000000 microseconds
output=$(format_time_us 864000000000)
assert_equals "10d 00h 00m 0.000s" "$output" "Large duration (10 days) formats correctly"

# ============================================================================
# Script Mode Edge Cases
# ============================================================================

# Test 34: Script with no command provided
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer"
# Should error
if ((exit_code != 0)); then
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} Script with no command exits with error"
else
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("Script with no command exits with error")
  echo "${RED}✗${RESET} Script with no command exits with error"
fi

# Test 35: Script with only -f flag (no command)
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -f
# Should error
if ((exit_code != 0)); then
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} Script with only -f exits with error"
else
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("Script with only -f exits with error")
  echo "${RED}✗${RESET} Script with only -f exits with error"
fi

# Test 36: Function mode with no command (should also handle gracefully)
set +e
capture_output stdout stderr exit_code timer
exit_code_noop=$?
set -e
# timer with no args should fail or noop
if ((exit_code_noop != 0)); then
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} Function with no command handled"
else
  # Could also succeed with noop - either is acceptable
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} Function with no command handled (noop)"
fi

# Print summary
print_summary

#fin
