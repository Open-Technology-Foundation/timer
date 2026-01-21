#!/bin/bash
# Test option parsing functionality
# - Script mode: -h, --help, -V, --version
# - Function mode: -h, -V behavior (noop)
# - Combined options: -fh, -fV, etc.
# - Invalid option handling

set -euo pipefail

# Load test framework
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
#shellcheck source=tests/test_framework.sh
source "$SCRIPT_DIR/test_framework.sh"

# Load timer as a sourced function for function mode tests
#shellcheck source=timer
source "$SCRIPT_DIR/../timer"

echo "${BLUE}Testing: Option Parsing${RESET}"
echo "======================================"

# ============================================================================
# Script Mode Tests
# ============================================================================

# Test 1: Script mode -h shows help
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -h
assert_success "$exit_code" "Script -h exits with 0"
assert_contains "$stdout" "Usage:" "Script -h shows usage"
assert_contains "$stdout" "High-precision command timer" "Script -h shows description"

# Test 2: Script mode --help shows help
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" --help
assert_success "$exit_code" "Script --help exits with 0"
assert_contains "$stdout" "Usage:" "Script --help shows usage"

# Test 3: Script mode -V shows version
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -V
assert_success "$exit_code" "Script -V exits with 0"
assert_matches "$stdout" 'timer [0-9]+\.[0-9]+\.[0-9]+' "Script -V shows version"

# Test 4: Script mode --version shows version
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" --version
assert_success "$exit_code" "Script --version exits with 0"
assert_matches "$stdout" 'timer [0-9]+\.[0-9]+\.[0-9]+' "Script --version shows version"

# Test 5: Script mode invalid option shows error
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -x echo "test"
assert_failure "$exit_code" 22 "Script invalid option exits with 22"
assert_contains "$stderr" "Invalid option" "Script invalid option shows error message"

# Test 6: Script mode invalid option shows usage
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" --invalid echo "test"
assert_failure "$exit_code" 22 "Script invalid long option exits with 22"
assert_contains "$stderr" "Usage:" "Script invalid option shows usage"

# Test 7: Script mode combined options -fh
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -fh
assert_success "$exit_code" "Script -fh exits with 0"
assert_contains "$stdout" "Usage:" "Script -fh shows help"

# Test 8: Script mode combined options -fV
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -fV
assert_success "$exit_code" "Script -fV exits with 0"
assert_matches "$stdout" 'timer [0-9]+\.[0-9]+\.[0-9]+' "Script -fV shows version"

# Test 9: Script mode combined options -hf
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -hf
assert_success "$exit_code" "Script -hf exits with 0"
assert_contains "$stdout" "Usage:" "Script -hf shows help"

# Test 10: Script mode combined options -Vf
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -Vf
assert_success "$exit_code" "Script -Vf exits with 0"
assert_matches "$stdout" 'timer [0-9]+\.[0-9]+\.[0-9]+' "Script -Vf shows version"

# Test 11: Script mode -f works with command
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -f echo "test"
assert_success "$exit_code" "Script -f executes command"
assert_equals "test" "$stdout" "Script -f command output preserved"
assert_not_matches "$stderr" '# timer: [0-9]+\.[0-9]{6}s$' "Script -f uses formatted output"

# ============================================================================
# Function Mode Tests
# ============================================================================

# Test 12: Function mode -h is noop (command still executes)
capture_output stdout stderr exit_code timer -h echo "test"
assert_success "$exit_code" "Function -h executes command"
assert_equals "test" "$stdout" "Function -h command output preserved"
assert_contains "$stderr" "# timer:" "Function -h shows timing"

# Test 13: Function mode --help is noop
capture_output stdout stderr exit_code timer --help echo "hello"
assert_success "$exit_code" "Function --help executes command"
assert_equals "hello" "$stdout" "Function --help command output preserved"

# Test 14: Function mode -V is noop (command still executes)
capture_output stdout stderr exit_code timer -V echo "test"
assert_success "$exit_code" "Function -V executes command"
assert_equals "test" "$stdout" "Function -V command output preserved"
assert_contains "$stderr" "# timer:" "Function -V shows timing"

# Test 15: Function mode --version is noop
capture_output stdout stderr exit_code timer --version echo "hello"
assert_success "$exit_code" "Function --version executes command"
assert_equals "hello" "$stdout" "Function --version command output preserved"

# Test 16: Function mode -h does not show help
capture_output stdout stderr exit_code timer -h echo "test"
assert_not_contains "$stdout" "Usage:" "Function -h does not show help"
assert_not_contains "$stderr" "Usage:" "Function -h does not show help in stderr"

# Test 17: Function mode -V does not show version
capture_output stdout stderr exit_code timer -V echo "test"
assert_not_matches "$stdout" 'timer [0-9]+\.[0-9]+\.[0-9]+' "Function -V does not show version"

# Test 18: Function mode with separate -f -h works
capture_output stdout stderr exit_code timer -f -h echo "test"
assert_success "$exit_code" "Function -f -h executes command"
assert_equals "test" "$stdout" "Function -f -h command output preserved"
assert_not_matches "$stderr" '# timer: [0-9]+\.[0-9]{6}s$' "Function -f -h uses formatted output"

# Test 19: Function mode with separate -f -V works
capture_output stdout stderr exit_code timer -f -V echo "test"
assert_success "$exit_code" "Function -f -V executes command"
assert_equals "test" "$stdout" "Function -f -V command output preserved"
assert_not_matches "$stderr" '# timer: [0-9]+\.[0-9]{6}s$' "Function -f -V uses formatted output"

# Test 20: Function mode -f works
capture_output stdout stderr exit_code timer -f echo "test"
assert_success "$exit_code" "Function -f executes command"
assert_not_matches "$stderr" '# timer: [0-9]+\.[0-9]{6}s$' "Function -f uses formatted output"

# Test 21: Function mode --format works
capture_output stdout stderr exit_code timer --format echo "test"
assert_success "$exit_code" "Function --format executes command"
assert_not_matches "$stderr" '# timer: [0-9]+\.[0-9]{6}s$' "Function --format uses formatted output"

# Test 22: Option parsing stops at first non-option argument
capture_output stdout stderr exit_code timer echo "-h"
assert_success "$exit_code" "Option parsing stops at command"
assert_equals "-h" "$stdout" "Literal -h passed to command"
assert_not_contains "$stdout" "Usage:" "Help not shown for command argument -h"

# Test 23: Options after command are passed to command
capture_output stdout stderr exit_code timer echo "test" -f
assert_success "$exit_code" "Options after command passed through"
assert_equals "test -f" "$stdout" "Command receives its own options"

# Print summary
print_summary

#fin
