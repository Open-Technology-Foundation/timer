#!/bin/bash
# Test runner for timer test suite
# Discovers and runs all test_*.sh files
# Provides summary reporting with color-coded output
# BCS compliant: pure Bash implementation

set -euo pipefail

declare -r VERSION='1.0.0'
declare -r SCRIPT_NAME=${0##*/}
declare -r SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Color codes for output (if terminal supports it)
if [[ -t 1 ]]; then
  declare -r RED=$'\033[0;31m'
  declare -r GREEN=$'\033[0;32m'
  declare -r YELLOW=$'\033[0;33m'
  declare -r BLUE=$'\033[0;34m'
  declare -r BOLD=$'\033[1m'
  declare -r RESET=$'\033[0m'
else
  declare -r RED='' GREEN='' YELLOW='' BLUE='' BOLD='' RESET=''
fi

# Global counters
declare -i TOTAL_PASSED=0 TOTAL_FAILED=0 TOTAL_TESTS=0
declare -a FAILED_FILES=()

# Usage information
usage() {
  cat <<EOT
$SCRIPT_NAME $VERSION - Timer test suite runner

Runs all test_*.sh files in the tests directory and reports results.

Usage: $SCRIPT_NAME [Options]

Options:
  -v, --verbose     Verbose output (show all test output)
  -f, --file FILE   Run only the specified test file
  -h, --help        Display this help message
  -V, --version     Display version information

Examples:
  $SCRIPT_NAME                    # Run all tests
  $SCRIPT_NAME -v                 # Run all tests with verbose output
  $SCRIPT_NAME -f test_basic.sh   # Run only test_basic.sh

EOT
  exit "${1:-0}"
}

# Run a single test file
run_test_file() {
  local -- test_file=$1 verbose=${2:-0}
  local -- test_name=${test_file##*/}
  test_name=${test_name%.sh}

  echo ""
  echo "${BOLD}${BLUE}Running: $test_name${RESET}"
  echo "========================================"

  local -- output
  local -i exit_code=0

  if ((verbose)); then
    # Show all output
    bash "$test_file" || exit_code=$?
  else
    # Capture output, only show on failure
    output=$(bash "$test_file" 2>&1) || exit_code=$?

    if ((exit_code != 0)); then
      echo "$output"
    else
      # Just show the summary line from output
      if [[ "$output" =~ Passed:\ ([0-9]+) ]]; then
        local -i passed=${BASH_REMATCH[1]}
        echo "${GREEN}All tests passed! ($passed)${RESET}"
      fi
    fi
  fi

  # Extract pass/fail counts from output
  if [[ "$output" =~ Total:\ \ ([0-9]+) ]]; then
    local -i total=${BASH_REMATCH[1]}
    TOTAL_TESTS+=total
  fi

  if [[ "$output" =~ Passed:\ ([0-9]+) ]]; then
    local -i passed=${BASH_REMATCH[1]}
    TOTAL_PASSED+=passed
  fi

  if [[ "$output" =~ Failed:\ ([0-9]+) ]]; then
    local -i failed=${BASH_REMATCH[1]}
    TOTAL_FAILED+=failed
    if ((failed > 0)); then
      FAILED_FILES+=("$test_name")
    fi
  fi

  if ((exit_code != 0)); then
    echo "${RED}✗ $test_name failed${RESET}"
    return 1
  else
    echo "${GREEN}✓ $test_name passed${RESET}"
    return 0
  fi
}

# Print final summary
print_final_summary() {
  echo ""
  echo "${BOLD}======================================${RESET}"
  echo "${BOLD}           FINAL SUMMARY${RESET}"
  echo "${BOLD}======================================${RESET}"

  if ((TOTAL_FAILED == 0)); then
    echo "${GREEN}${BOLD}All tests passed!${RESET}"
  else
    echo "${RED}${BOLD}Some tests failed:${RESET}"
    for file in "${FAILED_FILES[@]}"; do
      echo "  ${RED}✗${RESET} $file"
    done
  fi

  echo ""
  echo "Total Tests:  $TOTAL_TESTS"
  echo "Passed:       ${GREEN}$TOTAL_PASSED${RESET}"
  echo "Failed:       ${RED}$TOTAL_FAILED${RESET}"
  echo "${BOLD}======================================${RESET}"

  return "$TOTAL_FAILED"
}

# Main execution
main() {
  local -i verbose=0
  local -- test_file=''

  # Parse options
  while (($#)); do
    case $1 in
      -v|--verbose)
        verbose=1
        ;;
      -f|--file)
        if (($# < 2)); then
          >&2 echo "$SCRIPT_NAME: Option $1 requires an argument"
          usage 1
        fi
        test_file=$2
        shift
        ;;
      -h|--help)
        usage 0
        ;;
      -V|--version)
        echo "$SCRIPT_NAME $VERSION"
        exit 0
        ;;
      *)
        >&2 echo "$SCRIPT_NAME: Invalid option ${1@Q}"
        usage 1
        ;;
    esac
    shift
  done

  # Print header
  echo "${BOLD}${BLUE}======================================${RESET}"
  echo "${BOLD}${BLUE}    Timer Test Suite Runner${RESET}"
  echo "${BOLD}${BLUE}======================================${RESET}"

  # Run tests
  if [[ -n "$test_file" ]]; then
    # Run single test file
    local -- full_path="$SCRIPT_DIR/$test_file"
    if [[ ! -f "$full_path" ]]; then
      >&2 echo "${RED}Error: Test file not found: $test_file${RESET}"
      exit 1
    fi
    run_test_file "$full_path" "$verbose" || true
  else
    # Run all test files
    local -a test_files
    # Use array to store test files
    while IFS= read -r -d '' file; do
      test_files+=("$file")
    done < <(find "$SCRIPT_DIR" -name 'test_*.sh' -type f -print0 | sort -z)

    if ((${#test_files[@]} == 0)); then
      >&2 echo "${YELLOW}Warning: No test files found${RESET}"
      exit 0
    fi

    echo "Found ${#test_files[@]} test files"

    # Run each test file
    for file in "${test_files[@]}"; do
      run_test_file "$file" "$verbose" || true
    done
  fi

  # Print final summary
  print_final_summary
}

# Run main
main "$@"

#fin
