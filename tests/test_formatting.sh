#!/bin/bash
# Test formatted output functionality
# - Format flag (-f, --format)
# - Time unit calculations (days, hours, minutes, seconds)
# - Edge duration handling
# - Precision in formatted output

set -euo pipefail

# Load test framework
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
#shellcheck source=tests/test_framework.sh
source "$SCRIPT_DIR/test_framework.sh"

# Load timer as a sourced function
#shellcheck source=timer
source "$SCRIPT_DIR/../timer"

echo "${BLUE}Testing: Formatted Output${RESET}"
echo "======================================"

# Test 1: -f flag produces formatted output
capture_output stdout stderr exit_code timer -f true
assert_contains "$stderr" "# timer:" "Formatted output has timer prefix"
# Formatted output ends with 's' but should not have 6 decimal places like unformatted
assert_not_matches "$stderr" '# timer: 0\.[0-9]{6}s$' "Formatted output not in microsecond decimal format"

# Test 2: --format flag produces formatted output
capture_output stdout stderr exit_code timer --format true
assert_contains "$stderr" "# timer:" "Long format flag works"

# Test 3: Formatted output for very short duration (< 1 minute)
capture_output stdout stderr exit_code timer -f true
assert_matches "$stderr" '# timer: [0-9]+\.[0-9]{3}s' "Short duration shows seconds with 3 decimals"

# Test 4: Test format_time_us directly with known values
# 500 milliseconds = 500,000 microseconds
output=$(format_time_us 500000)
assert_equals "0.500s" "$output" "500ms formats as 0.500s"

# Test 5: Exactly 1 second
output=$(format_time_us 1000000)
assert_equals "1.000s" "$output" "1 second formats as 1.000s"

# Test 6: Just under 1 minute (59.999 seconds)
output=$(format_time_us 59999000)
assert_equals "59.999s" "$output" "59.999s stays in seconds"

# Test 7: Exactly 1 minute
output=$(format_time_us 60000000)
assert_equals "01m 0.000s" "$output" "60s formats as 01m 0.000s"

# Test 8: 1 minute and some seconds
output=$(format_time_us 61500000)
assert_equals "01m 1.500s" "$output" "61.5s formats as 01m 1.500s"

# Test 9: Multiple minutes
output=$(format_time_us 150000000)
assert_equals "02m 30.000s" "$output" "150s formats as 02m 30.000s"

# Test 10: Just under 1 hour (59m 59.999s)
output=$(format_time_us 3599999000)
assert_equals "59m 59.999s" "$output" "Just under 1 hour shows minutes"

# Test 11: Exactly 1 hour
output=$(format_time_us 3600000000)
assert_equals "01h 00m 0.000s" "$output" "3600s formats as 01h 00m 0.000s"

# Test 12: 1 hour and some time
output=$(format_time_us 3661000000)
assert_equals "01h 01m 1.000s" "$output" "3661s formats as 01h 01m 1.000s"

# Test 13: Multiple hours with zero padding
output=$(format_time_us 7384500000)
assert_equals "02h 03m 4.500s" "$output" "Zero padding in hours and minutes (02h 03m)"

# Test 14: Just under 1 day (23h 59m 59.999s)
output=$(format_time_us 86399999000)
assert_equals "23h 59m 59.999s" "$output" "Just under 1 day shows hours"

# Test 15: Exactly 1 day
output=$(format_time_us 86400000000)
assert_equals "1d 00h 00m 0.000s" "$output" "86400s formats as 1d 00h 00m 0.000s"

# Test 16: Multiple days with zero padding
output=$(format_time_us 90061000000)
assert_equals "1d 01h 01m 1.000s" "$output" "Zero padding in hours and minutes (1d 01h 01m)"

# Test 17: Large number of days
output=$(format_time_us 864000000000)
assert_equals "10d 00h 00m 0.000s" "$output" "10 days formats correctly"

# Test 18: Zero duration
output=$(format_time_us 0)
assert_equals "0.000s" "$output" "Zero duration formats as 0.000s"

# Test 19: 1 microsecond
output=$(format_time_us 1)
assert_matches "$output" '^0\.000s$' "1 microsecond rounds to 0.000s"

# Test 20: 999 microseconds
output=$(format_time_us 999)
assert_matches "$output" '^0\.00[01]s$' "999 microseconds rounds to 0.001s or 0.000s"

# Test 21: 1 millisecond (1000 microseconds)
output=$(format_time_us 1000)
assert_equals "0.001s" "$output" "1ms formats as 0.001s"

# Test 22: Microsecond precision preserved in formatted output
output=$(format_time_us 1234567)
assert_equals "1.235s" "$output" "1.234567s rounds to 1.235s (3 decimals)"

# Test 23: Complex time with all units
output=$(format_time_us 90061234567)
assert_matches "$output" '^1d 01h 01m 1\.23[45]s$' "Complex time has all units with zero padding"

# Test 24: Timer -f with actual command
capture_output stdout stderr exit_code timer -f sleep 0.01
assert_success "$exit_code" "Timer -f executes command"
# Should have formatted output, not decimal seconds
assert_not_matches "$stderr" '# timer: 0\.[0-9]{6}s$' "Formatted output not in microsecond format"

# Print summary
print_summary

#fin
