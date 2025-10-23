#!/bin/bash
# Test errexit (set -e) preservation and interaction
# - Caller's errexit state is preserved after timer()
# - Commands can fail within timer() without terminating caller
# - Multiple timer() calls maintain correct state
# - Nested function interactions

set -euo pipefail

# Load test framework
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
#shellcheck source=tests/test_framework.sh
source "$SCRIPT_DIR/test_framework.sh"

# Load timer as a sourced function
#shellcheck source=timer
source "$SCRIPT_DIR/../timer"

echo "${BLUE}Testing: errexit Preservation${RESET}"
echo "======================================"

# ============================================================================
# errexit State Preservation Tests
# ============================================================================

# Test 1: Caller with set -e enabled - state preserved after timer()
test_errexit_preserved_enabled() {
  set -e
  timer true >/dev/null 2>&1
  if [[ $- == *e* ]]; then
    echo "PASS"
  else
    echo "FAIL: set -e not preserved"
  fi
}
result=$(test_errexit_preserved_enabled)
assert_equals "PASS" "$result" "Caller's set -e preserved after timer()"

# Test 2: Caller with set -e disabled - state preserved after timer()
test_errexit_preserved_disabled() {
  set +e
  timer true >/dev/null 2>&1
  if [[ $- != *e* ]]; then
    echo "PASS"
  else
    echo "FAIL: set +e not preserved (set -e enabled)"
  fi
  set -e  # Re-enable for test framework
}
result=$(test_errexit_preserved_disabled)
assert_equals "PASS" "$result" "Caller's set +e preserved after timer()"

# Test 3: Failing command within timer() doesn't terminate caller (with set -e)
test_failing_command_no_terminate() {
  set -e
  timer false >/dev/null 2>&1 || true
  echo "SURVIVED"
}
result=$(test_failing_command_no_terminate)
assert_equals "SURVIVED" "$result" "Failing command in timer() doesn't terminate caller"

# Test 4: timer() captures failing command exit code correctly
test_timer_captures_exit_code() {
  set -e
  local -i exit_code=0
  timer bash -c 'exit 42' >/dev/null 2>&1 || exit_code=$?
  echo "$exit_code"
}
result=$(test_timer_captures_exit_code)
assert_equals "42" "$result" "timer() captures command exit code 42"

# Test 5: Multiple timer() calls maintain errexit state
test_multiple_timer_calls() {
  set -e
  timer true >/dev/null 2>&1
  timer true >/dev/null 2>&1
  timer true >/dev/null 2>&1
  if [[ $- == *e* ]]; then
    echo "PASS"
  else
    echo "FAIL"
  fi
}
result=$(test_multiple_timer_calls)
assert_equals "PASS" "$result" "Multiple timer() calls preserve set -e"

# Test 6: timer() with failing command, then successful command
test_fail_then_success() {
  set -e
  local -i exit1=0 exit2=0
  timer false >/dev/null 2>&1 || exit1=$?
  timer true >/dev/null 2>&1 || exit2=$?
  echo "$exit1:$exit2"
}
result=$(test_fail_then_success)
assert_equals "1:0" "$result" "timer() handles failure then success"

# Test 7: timer() within a function that has set -e
test_timer_in_function_with_errexit() {
  test_inner_func() {
    set -e
    timer true >/dev/null 2>&1
    if [[ $- == *e* ]]; then
      echo "PASS"
    else
      echo "FAIL"
    fi
  }
  test_inner_func
}
result=$(test_timer_in_function_with_errexit)
assert_equals "PASS" "$result" "timer() in function preserves function's set -e"

# Test 8: Caller can continue after timer() with failing command
test_continue_after_fail() {
  set -e
  local -i count=0
  timer false >/dev/null 2>&1 || true
  count+=1
  timer false >/dev/null 2>&1 || true
  count+=1
  echo "$count"
}
result=$(test_continue_after_fail)
assert_equals "2" "$result" "Caller continues after multiple timer() failures"

# Test 9: timer() doesn't affect errexit in different contexts
test_errexit_contexts() {
  # Test with set -e
  set -e
  local -i exit_code=0
  timer bash -c 'exit 5' >/dev/null 2>&1 || exit_code=$?

  # Test with set +e
  set +e
  timer true >/dev/null 2>&1
  local -- state1="$-"

  # Test with set -e again
  set -e
  timer true >/dev/null 2>&1
  local -- state2="$-"

  if [[ "$state1" != *e* && "$state2" == *e* ]]; then
    echo "PASS"
  else
    echo "FAIL"
  fi
  set -e
}
result=$(test_errexit_contexts)
assert_equals "PASS" "$result" "timer() respects errexit in different contexts"

# Test 10: Nested timer() calls preserve errexit
test_nested_timer() {
  set -e
  outer_func() {
    timer bash -c 'timer true >/dev/null 2>&1; echo "nested"' 2>/dev/null
  }
  local -- output
  output=$(outer_func 2>&1 || echo "FAILED")
  if [[ "$output" == *"nested"* && "$output" != *"FAILED"* ]]; then
    echo "PASS"
  else
    echo "FAIL"
  fi
}
result=$(test_nested_timer)
assert_equals "PASS" "$result" "Nested timer() calls work correctly"

# Test 11: timer() after a naturally failing command in script
test_after_natural_fail() {
  set +e
  false
  set -e
  timer true >/dev/null 2>&1
  echo "SURVIVED"
}
result=$(test_after_natural_fail)
assert_equals "SURVIVED" "$result" "timer() works after natural command failure"

# Test 12: Complex errexit scenario - pipeline with timer
test_pipeline_with_timer() {
  set -e
  local -- result
  result=$(timer echo "test" 2>/dev/null | tr 'a-z' 'A-Z')
  echo "$result"
}
result=$(test_pipeline_with_timer)
assert_equals "TEST" "$result" "timer() works in pipeline with set -e"

# Test 13: timer() preserves errexit across subshells
test_subshell_errexit() {
  set -e
  (
    timer true >/dev/null 2>&1
    if [[ $- == *e* ]]; then
      echo "PASS"
    else
      echo "FAIL"
    fi
  )
}
result=$(test_subshell_errexit)
assert_equals "PASS" "$result" "timer() preserves errexit in subshells"

# Test 14: timer() exit code can be used in conditionals
test_exit_code_in_conditional() {
  set -e
  local -- result="FAIL"
  if timer true >/dev/null 2>&1; then
    result="PASS"
  fi
  echo "$result"
}
result=$(test_exit_code_in_conditional)
assert_equals "PASS" "$result" "timer() exit code works in if conditional"

# Test 15: timer() with command that has internal set -e
test_command_with_set_e() {
  set -e
  local -i exit_code=0
  timer bash -c 'set -e; false; echo "should not reach"' >/dev/null 2>&1 || exit_code=$?
  if ((exit_code != 0)); then
    echo "PASS"
  else
    echo "FAIL: command with set -e didn't fail"
  fi
}
result=$(test_command_with_set_e)
assert_equals "PASS" "$result" "timer() respects command's internal set -e"

# Print summary
print_summary

#fin
