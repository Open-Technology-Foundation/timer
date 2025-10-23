#!/bin/bash
# Test timing accuracy and arithmetic correctness
# - EPOCHREALTIME conversion to microseconds
# - Integer arithmetic validation
# - Printf scientific notation accuracy
# - format_time_us calculations
# - Time constants correctness
# - Pure Bash implementation validation

set -euo pipefail

# Load test framework
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
#shellcheck source=tests/test_framework.sh
source "$SCRIPT_DIR/test_framework.sh"

# Load timer as a sourced function
#shellcheck source=timer
source "$SCRIPT_DIR/../timer"

echo "${BLUE}Testing: Accuracy and Arithmetic${RESET}"
echo "======================================"

# ============================================================================
# EPOCHREALTIME Conversion Tests
# ============================================================================

# Test 1: EPOCHREALTIME is available
if [[ -n "${EPOCHREALTIME:-}" ]]; then
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} EPOCHREALTIME is available"
else
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("EPOCHREALTIME is available")
  echo "${RED}✗${RESET} EPOCHREALTIME is available"
  echo "  Requires Bash 5.2+"
fi

# Test 2: EPOCHREALTIME format validation
if [[ "$EPOCHREALTIME" =~ ^[0-9]+\.[0-9]{6}$ ]]; then
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} EPOCHREALTIME format is correct (seconds.microseconds)"
else
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("EPOCHREALTIME format validation")
  echo "${RED}✗${RESET} EPOCHREALTIME format validation"
  echo "  Expected: NNNNNNNNNN.NNNNNN"
  echo "  Actual:   $EPOCHREALTIME"
fi

# Test 3: Decimal removal produces integer
test_val="${EPOCHREALTIME//./}"
if [[ "$test_val" =~ ^[0-9]+$ ]]; then
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} Decimal removal produces integer"
else
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("Decimal removal produces integer")
  echo "${RED}✗${RESET} Decimal removal produces integer"
fi

# ============================================================================
# Printf Scientific Notation Tests
# ============================================================================

# Test 4: Printf with e-6 converts microseconds to seconds
result=$(printf "%.6f" "1000000e-6")
assert_equals "1.000000" "$result" "Printf 1000000e-6 = 1.000000s"

# Test 5: Printf with e-6 handles small values
result=$(printf "%.6f" "1e-6")
assert_equals "0.000001" "$result" "Printf 1e-6 = 0.000001s"

# Test 6: Printf with e-6 handles zero
result=$(printf "%.6f" "0e-6")
assert_equals "0.000000" "$result" "Printf 0e-6 = 0.000000s"

# Test 7: Printf with e-6 handles large values
result=$(printf "%.6f" "123456789e-6")
assert_equals "123.456789" "$result" "Printf 123456789e-6 = 123.456789s"

# Test 8: Printf with 3 decimals for formatted output
result=$(printf "%.3f" "1234567e-6")
assert_equals "1.235" "$result" "Printf 1234567e-6 = 1.235s (3 decimals)"

# ============================================================================
# Integer Arithmetic Tests
# ============================================================================

# Test 9: Microsecond subtraction
start_us=1234567890123456
end_us=1234567890623456
elapsed=$((end_us - start_us))
assert_equals "500000" "$elapsed" "Microsecond subtraction: 500000"

# Test 10: Division for time unit conversion
microseconds=3661000000  # 1 hour, 1 minute, 1 second
seconds=$((microseconds / 1000000))
assert_equals "3661" "$seconds" "Microseconds to seconds division"

# Test 11: Modulo for remaining time
total_us=90000000  # 90 seconds
minutes=$((total_us / 60000000))
remaining_us=$((total_us - minutes * 60000000))
assert_equals "1" "$minutes" "90s = 1 minute"
assert_equals "30000000" "$remaining_us" "90s - 1m = 30s (in microseconds)"

# Test 12: Base-10 enforcement prevents octal interpretation
# Leading zeros should not cause octal interpretation with 10# prefix
val="0000123"
result=$((10#$val))
assert_equals "123" "$result" "Base-10 prefix prevents octal interpretation"

# ============================================================================
# format_time_us Time Constant Tests
# ============================================================================

# Test 13: Day constant (86400 seconds * 1,000,000)
expected_day_us=86400000000
# Can't easily extract the constant, so verify through function behavior
output=$(format_time_us "$expected_day_us")
assert_equals "1d 00h 00m 0.000s" "$output" "Day constant correct: 86400000000 us"

# Test 14: Hour constant (3600 seconds * 1,000,000)
expected_hour_us=3600000000
output=$(format_time_us "$expected_hour_us")
assert_equals "01h 00m 0.000s" "$output" "Hour constant correct: 3600000000 us"

# Test 15: Minute constant (60 seconds * 1,000,000)
expected_minute_us=60000000
output=$(format_time_us "$expected_minute_us")
assert_equals "01m 0.000s" "$output" "Minute constant correct: 60000000 us"

# Test 16: Multiple days calculation
output=$(format_time_us 172800000000)  # 2 days
assert_equals "2d 00h 00m 0.000s" "$output" "2 days calculation correct"

# Test 17: Complex time calculation
# 1d 2h 3m 4.567s = 86400 + 7200 + 180 + 4.567 = 93784.567s = 93784567000us
output=$(format_time_us 93784567000)
assert_equals "1d 02h 03m 4.567s" "$output" "Complex time calculation correct"

# ============================================================================
# Timing Accuracy Tests (Real Commands)
# ============================================================================

# Test 18: Sleep 0.1 seconds timing accuracy (within tolerance)
start_time=${EPOCHREALTIME//./}
sleep 0.1
end_time=${EPOCHREALTIME//./}
elapsed=$((end_time - start_time))
# Should be approximately 100000 microseconds (100ms), allow ±20000 (±20ms)
if ((elapsed >= 80000 && elapsed <= 120000)); then
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} Sleep 0.1s timing within tolerance (${elapsed}us)"
else
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("Sleep 0.1s timing accuracy")
  echo "${RED}✗${RESET} Sleep 0.1s timing accuracy"
  echo "  Expected: 80000-120000us"
  echo "  Actual:   ${elapsed}us"
fi

# Test 19: Very short command overhead is reasonable
start_time=${EPOCHREALTIME//./}
true
end_time=${EPOCHREALTIME//./}
elapsed=$((end_time - start_time))
# Should be very small, but not zero (some overhead exists)
# Allow up to 10ms (10000us) for overhead
if ((elapsed < 10000)); then
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} Very short command overhead reasonable (${elapsed}us < 10ms)"
else
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("Very short command overhead")
  echo "${RED}✗${RESET} Very short command overhead"
  echo "  Expected: < 10000us"
  echo "  Actual:   ${elapsed}us"
fi

# Test 20: Timer overhead is minimal (compare timer vs direct)
# Direct measurement
start_time=${EPOCHREALTIME//./}
sleep 0.05
end_time=${EPOCHREALTIME//./}
direct_elapsed=$((end_time - start_time))

# Timer measurement
capture_output stdout stderr exit_code timer sleep 0.05
if [[ "$stderr" =~ timer:\ ([0-9]+\.[0-9]+)s ]]; then
  timer_seconds=${BASH_REMATCH[1]}
  # Convert to microseconds for comparison
  timer_elapsed=$(printf "%.0f" "$(printf "%.6f" "${timer_seconds}e6")")

  # Timer overhead should be < 5ms (5000us) compared to direct
  overhead=$((timer_elapsed - direct_elapsed))
  if ((overhead < 5000 && overhead > -5000)); then
    TESTS_PASSED+=1
    TESTS_TOTAL+=1
    echo "${GREEN}✓${RESET} Timer overhead minimal (${overhead}us)"
  else
    TESTS_FAILED+=1
    TESTS_TOTAL+=1
    FAILED_TESTS+=("Timer overhead minimal")
    echo "${RED}✗${RESET} Timer overhead minimal"
    echo "  Expected: < 5000us difference"
    echo "  Actual:   ${overhead}us"
  fi
else
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("Timer overhead measurement")
  echo "${RED}✗${RESET} Timer overhead measurement"
fi

# ============================================================================
# Edge Value Arithmetic Tests
# ============================================================================

# Test 21: format_time_us with 1 microsecond
output=$(format_time_us 1)
assert_matches "$output" '^0\.00[01]s$' "1 microsecond formats correctly"

# Test 22: format_time_us with 999999 microseconds (just under 1 second)
output=$(format_time_us 999999)
assert_equals "1.000s" "$output" "999999us rounds to 1.000s"

# Test 23: format_time_us with 59999999 microseconds (just under 1 minute)
output=$(format_time_us 59999999)
assert_matches "$output" '^(59\.999s|60\.000s|01m 0\.000s)$' "59999999us near 1 minute (rounding)"

# Test 24: format_time_us boundary test - exactly at day boundary minus 1us
output=$(format_time_us 86399999999)
assert_matches "$output" '^(23h 59m 59\.999s|23h 59m 60\.000s|1d 00h 00m 0\.000s)$' "Day boundary minus 1us (rounding)"

# Test 25: Large value calculation (100 days)
output=$(format_time_us 8640000000000)
assert_equals "100d 00h 00m 0.000s" "$output" "100 days formats correctly"

# ============================================================================
# Pure Bash Validation
# ============================================================================

# Test 26: Verify no external commands in timer function
# Check the function definition doesn't contain awk, bc, date, etc.
timer_func=$(declare -f timer)
if [[ "$timer_func" =~ (awk|bc|date|perl|python|ruby|expr) ]]; then
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("Pure Bash - no external commands")
  echo "${RED}✗${RESET} Pure Bash - timer uses external commands"
else
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} Pure Bash - timer has no external commands"
fi

# Test 27: Verify no external commands in format_time_us function
format_func=$(declare -f format_time_us)
if [[ "$format_func" =~ (awk|bc|date|perl|python|ruby|expr) ]]; then
  TESTS_FAILED+=1
  TESTS_TOTAL+=1
  FAILED_TESTS+=("Pure Bash - format_time_us no external commands")
  echo "${RED}✗${RESET} Pure Bash - format_time_us uses external commands"
else
  TESTS_PASSED+=1
  TESTS_TOTAL+=1
  echo "${GREEN}✓${RESET} Pure Bash - format_time_us has no external commands"
fi

# Print summary
print_summary

#fin
