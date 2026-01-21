#!/bin/bash
# Test JSON output functionality
# - JSON format validation
# - All required fields present
# - Type correctness (integer vs float)
# - Exit code preservation
# - Command array formatting
# - Special character escaping
# - Combined options (-fj, -jf)

set -euo pipefail

# Load test framework
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
#shellcheck source=tests/test_framework.sh
source "$SCRIPT_DIR/test_framework.sh"

# Load timer as a sourced function for function mode tests
#shellcheck source=timer
source "$SCRIPT_DIR/../timer"

echo "${BLUE}Testing: JSON Output${RESET}"
echo "======================================"

# ============================================================================
# Basic JSON Output Tests
# ============================================================================

# Test 1: -j flag produces JSON output
capture_output stdout stderr exit_code timer -j true
assert_success "$exit_code" "-j flag executes command"
assert_contains "$stderr" '{"elapsed_us":' "-j produces JSON output"

# Test 2: --json flag produces JSON output
capture_output stdout stderr exit_code timer --json true
assert_success "$exit_code" "--json flag executes command"
assert_contains "$stderr" '{"elapsed_us":' "--json produces JSON output"

# Test 3: JSON contains elapsed_us as integer
capture_output stdout stderr exit_code timer -j true
assert_matches "$stderr" '"elapsed_us":[0-9]+,' "JSON elapsed_us is integer"

# Test 4: JSON contains elapsed_s as float
capture_output stdout stderr exit_code timer -j true
assert_matches "$stderr" '"elapsed_s":[0-9]+\.[0-9]{6},' "JSON elapsed_s is float with 6 decimals"

# Test 5: JSON contains elapsed_formatted string
capture_output stdout stderr exit_code timer -j sleep 0.01
assert_matches "$stderr" '"elapsed_formatted":"[0-9]+\.[0-9]+s"' "JSON elapsed_formatted is string"

# Test 6: JSON contains exit_code field
capture_output stdout stderr exit_code timer -j true
assert_contains "$stderr" '"exit_code":0' "JSON exit_code is 0 for successful command"

# Test 7: JSON contains command array
capture_output stdout stderr exit_code timer -j echo "hello"
assert_contains "$stderr" '"command":["echo","hello"]' "JSON command is array"

# ============================================================================
# Exit Code Tests
# ============================================================================

# Test 8: JSON exit_code reflects command failure
capture_output stdout stderr exit_code timer -j false
assert_failure "$exit_code" 1 "Timer returns command exit code"
assert_contains "$stderr" '"exit_code":1' "JSON exit_code is 1 for failed command"

# Test 9: JSON exit_code preserves specific exit codes
capture_output stdout stderr exit_code timer -j bash -c 'exit 42'
assert_failure "$exit_code" 42 "Timer returns specific exit code"
assert_contains "$stderr" '"exit_code":42' "JSON exit_code is 42"

# ============================================================================
# Command Array Tests
# ============================================================================

# Test 10: Multi-argument command in JSON
capture_output stdout stderr exit_code timer -j echo "one" "two" "three"
assert_contains "$stderr" '"command":["echo","one","two","three"]' "JSON command array with multiple args"

# Test 11: Single command in JSON
capture_output stdout stderr exit_code timer -j true
assert_contains "$stderr" '"command":["true"]' "JSON command array with single element"

# ============================================================================
# Special Character Escaping Tests
# ============================================================================

# Test 12: Quotes in arguments are escaped
capture_output stdout stderr exit_code timer -j echo 'with "quotes"'
assert_contains "$stderr" 'with \"quotes\"' "JSON escapes double quotes"

# Test 13: Backslashes in arguments are escaped
capture_output stdout stderr exit_code timer -j echo 'back\slash'
assert_contains "$stderr" 'back\\slash' "JSON escapes backslashes"

# Test 14: Spaces in arguments preserved
capture_output stdout stderr exit_code timer -j echo "hello world"
assert_contains "$stderr" '"hello world"' "JSON preserves spaces in quoted args"

# ============================================================================
# Combined Options Tests
# ============================================================================

# Test 15: -fj works (formatted flag is ignored in JSON mode)
capture_output stdout stderr exit_code timer -fj true
assert_success "$exit_code" "-fj executes command"
assert_contains "$stderr" '{"elapsed_us":' "-fj produces JSON output"

# Test 16: -jf works
capture_output stdout stderr exit_code timer -jf true
assert_success "$exit_code" "-jf executes command"
assert_contains "$stderr" '{"elapsed_us":' "-jf produces JSON output"

# Test 17: Script mode -j works
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -j true
assert_success "$exit_code" "Script -j executes command"
assert_contains "$stderr" '{"elapsed_us":' "Script -j produces JSON output"

# Test 18: Script mode --json works
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" --json true
assert_success "$exit_code" "Script --json executes command"
assert_contains "$stderr" '{"elapsed_us":' "Script --json produces JSON output"

# Test 19: Script mode -fj combined option
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -fj true
assert_success "$exit_code" "Script -fj executes command"
assert_contains "$stderr" '{"elapsed_us":' "Script -fj produces JSON output"

# ============================================================================
# Output Destination Tests
# ============================================================================

# Test 20: JSON goes to stderr, stdout preserved
capture_output stdout stderr exit_code timer -j echo "command output"
assert_equals "command output" "$stdout" "JSON: stdout contains command output"
assert_contains "$stderr" '{"elapsed_us":' "JSON: stderr contains JSON"

# Test 21: JSON output is single line (no pretty printing)
capture_output stdout stderr exit_code timer -j true
# Count newlines in JSON - should be exactly 2 (leading blank line + JSON line)
declare -i newline_count
newline_count=$(echo "$stderr" | wc -l)
assert_equals "2" "$newline_count" "JSON output is single line"

# ============================================================================
# JSON Structure Validation
# ============================================================================

# Test 22: JSON is well-formed (all required fields present)
capture_output stdout stderr exit_code timer -j echo "test"
assert_matches "$stderr" '"elapsed_us":[0-9]+' "JSON has elapsed_us field"
assert_matches "$stderr" '"elapsed_s":[0-9]+\.[0-9]+' "JSON has elapsed_s field"
assert_matches "$stderr" '"elapsed_formatted":"[^"]+"' "JSON has elapsed_formatted field"
assert_matches "$stderr" '"exit_code":[0-9]+' "JSON has exit_code field"
assert_matches "$stderr" '"command":\[' "JSON has command field"

# Print summary
print_summary

#fin
