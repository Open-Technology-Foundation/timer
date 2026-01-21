#!/bin/bash
# Test output file option (-o, --output-to)
# - Redirect timing output to file
# - Default output to stderr
# - Works with all output modes (-f, -j)
# - Preserves command stdout

set -euo pipefail

# Load test framework
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
#shellcheck source=tests/test_framework.sh
source "$SCRIPT_DIR/test_framework.sh"

# Load timer as a sourced function for function mode tests
#shellcheck source=timer
source "$SCRIPT_DIR/../timer"

echo "${BLUE}Testing: Output File Option${RESET}"
echo "======================================"

# Create temp directory for output files
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# ============================================================================
# Script Mode Tests
# ============================================================================

# Test 1: Script mode -o writes to file
output_file="$TMPDIR/test1.txt"
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -o "$output_file" echo "hello"
assert_success "$exit_code" "Script -o executes command"
assert_equals "hello" "$stdout" "Script -o preserves command stdout"
file_content=$(<"$output_file")
assert_matches "$file_content" '# timer: [0-9]+\.[0-9]+s' "Script -o writes timing to file"

# Test 2: Script mode --output-to writes to file
output_file="$TMPDIR/test2.txt"
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" --output-to "$output_file" echo "world"
assert_success "$exit_code" "Script --output-to executes command"
assert_equals "world" "$stdout" "Script --output-to preserves command stdout"
file_content=$(<"$output_file")
assert_matches "$file_content" '# timer: [0-9]+\.[0-9]+s' "Script --output-to writes timing to file"

# Test 3: Script mode default output goes to stderr
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" echo "test"
assert_success "$exit_code" "Script default output executes command"
assert_contains "$stderr" "# timer:" "Script default outputs timing to stderr"

# Test 4: Script mode -o with -f (formatted output)
output_file="$TMPDIR/test4.txt"
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -f -o "$output_file" sleep 0.01
assert_success "$exit_code" "Script -f -o executes command"
file_content=$(<"$output_file")
assert_matches "$file_content" '# timer: [0-9]+\.[0-9]+s' "Script -f -o writes formatted timing to file"
assert_not_matches "$file_content" '^\n# timer: [0-9]+\.[0-9]{6}s$' "Script -f -o uses formatted output"

# Test 5: Script mode -o with -j (JSON output)
output_file="$TMPDIR/test5.json"
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -j -o "$output_file" echo "json test"
assert_success "$exit_code" "Script -j -o executes command"
assert_equals "json test" "$stdout" "Script -j -o preserves command stdout"
file_content=$(<"$output_file")
assert_contains "$file_content" '"elapsed_us":' "Script -j -o writes JSON to file"
assert_contains "$file_content" '"exit_code":0' "Script -j -o includes exit code in JSON"

# Test 6: Script mode -o option order (-o before -f)
output_file="$TMPDIR/test6.txt"
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -o "$output_file" -f echo "test"
assert_success "$exit_code" "Script -o -f executes command"
file_content=$(<"$output_file")
assert_matches "$file_content" '# timer:' "Script -o -f writes to file"

# Test 7: Script mode -o option order (-f before -o)
output_file="$TMPDIR/test7.txt"
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -f -o "$output_file" echo "test"
assert_success "$exit_code" "Script -f -o executes command"
file_content=$(<"$output_file")
assert_matches "$file_content" '# timer:' "Script -f -o writes to file"

# Test 8: Script mode -o appends to existing file
output_file="$TMPDIR/test8.txt"
echo "existing content" > "$output_file"
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -o "$output_file" echo "append test"
assert_success "$exit_code" "Script -o appends executes command"
file_content=$(<"$output_file")
assert_contains "$file_content" "existing content" "Script -o preserves existing content"
assert_contains "$file_content" "# timer:" "Script -o appends timing"

# Test 9: Script mode -o with /dev/stderr explicitly
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -o /dev/stderr echo "stderr test"
assert_success "$exit_code" "Script -o /dev/stderr executes command"
assert_contains "$stderr" "# timer:" "Script -o /dev/stderr outputs to stderr"

# ============================================================================
# Function Mode Tests
# ============================================================================

# Test 10: Function mode -o writes to file
output_file="$TMPDIR/test10.txt"
capture_output stdout stderr exit_code timer -o "$output_file" echo "func hello"
assert_success "$exit_code" "Function -o executes command"
assert_equals "func hello" "$stdout" "Function -o preserves command stdout"
file_content=$(<"$output_file")
assert_matches "$file_content" '# timer: [0-9]+\.[0-9]+s' "Function -o writes timing to file"

# Test 11: Function mode --output-to writes to file
output_file="$TMPDIR/test11.txt"
capture_output stdout stderr exit_code timer --output-to "$output_file" echo "func world"
assert_success "$exit_code" "Function --output-to executes command"
file_content=$(<"$output_file")
assert_matches "$file_content" '# timer: [0-9]+\.[0-9]+s' "Function --output-to writes timing to file"

# Test 12: Function mode default output goes to stderr
capture_output stdout stderr exit_code timer echo "func test"
assert_success "$exit_code" "Function default output executes command"
assert_contains "$stderr" "# timer:" "Function default outputs timing to stderr"

# Test 13: Function mode -o with -f
output_file="$TMPDIR/test13.txt"
capture_output stdout stderr exit_code timer -f -o "$output_file" echo "test"
assert_success "$exit_code" "Function -f -o executes command"
file_content=$(<"$output_file")
assert_contains "$file_content" "# timer:" "Function -f -o writes to file"

# Test 14: Function mode -o with -j
output_file="$TMPDIR/test14.json"
capture_output stdout stderr exit_code timer -j -o "$output_file" echo "json"
assert_success "$exit_code" "Function -j -o executes command"
file_content=$(<"$output_file")
assert_contains "$file_content" '"elapsed_us":' "Function -j -o writes JSON to file"

# Test 15: Function mode -o file doesn't pollute stderr
output_file="$TMPDIR/test15.txt"
capture_output stdout stderr exit_code timer -o "$output_file" echo "no stderr"
assert_success "$exit_code" "Function -o file executes command"
assert_not_contains "$stderr" "# timer:" "Function -o file doesn't output to stderr"

# Test 16: Function mode combined -fj with -o
output_file="$TMPDIR/test16.json"
capture_output stdout stderr exit_code timer -f -j -o "$output_file" echo "combined"
assert_success "$exit_code" "Function -fj -o executes command"
file_content=$(<"$output_file")
assert_contains "$file_content" '"elapsed_us":' "Function -fj -o writes JSON to file"

# ============================================================================
# Edge Cases
# ============================================================================

# Test 17: Exit status preserved with -o
output_file="$TMPDIR/test17.txt"
capture_output stdout stderr exit_code timer -o "$output_file" false
assert_failure "$exit_code" 1 "Timer preserves exit code with -o"

# Test 18: -o with command that has -o argument
output_file="$TMPDIR/test18.txt"
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -o "$output_file" echo "-o"
assert_success "$exit_code" "Script -o handles command with -o arg"
assert_equals "-o" "$stdout" "Command receives -o as argument"

# Test 19: -- separator with -o after (timer function still processes options)
# Note: The -- separator stops script mode parsing, but timer function still
# processes options from cmd_args. This is expected behavior.
output_file="$TMPDIR/test19.txt"
capture_output stdout stderr exit_code "$SCRIPT_DIR/../timer" -- -o "$output_file" echo "after separator"
assert_success "$exit_code" "Script -- with -o executes command"
assert_equals "after separator" "$stdout" "Script -- with -o preserves stdout"
# Timer function processes -o from cmd_args, writing to the specified file
file_content=$(<"$output_file")
assert_contains "$file_content" "# timer:" "Script -- with -o writes to file (function processes options)"

# Print summary
print_summary

#fin
