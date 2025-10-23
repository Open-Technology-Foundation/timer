# Timer Test Suite

**100% Pure Bash** test suite for the timer library with zero external dependencies.

## Quick Start

```bash
cd tests
./run_tests.sh
```

## Test Suite Philosophy

This test suite follows the same principles as the timer implementation:

- **100% Pure Bash** - No external test frameworks (bats, shunit2, etc.)
- **Zero Dependencies** - Only Bash 5.2+ required
- **BCS Compliant** - All test code follows [BASH-CODING-STANDARD](https://github.com/Open-Technology-Foundation/bash-coding-standard)
- **Fast & Deterministic** - Tests are repeatable and minimize sleep usage
- **Comprehensive Coverage** - Tests all functionality, edge cases, and error conditions

## Test Files

### Core Test Files

| File | Coverage | Test Count |
|------|----------|------------|
| `test_basic.sh` | Core timing, exit status, stdout/stderr separation | 13 tests |
| `test_formatting.sh` | Format flag, time unit calculations, edge durations | 24 tests |
| `test_options.sh` | Option parsing, combined options, script vs function modes | 23 tests |
| `test_modes.sh` | Script vs sourced behavior, function export, state isolation | 17 tests |
| `test_errexit.sh` | errexit preservation, set -e interactions, state management | 15 tests |
| `test_edge_cases.sh` | Special chars, empty commands, stdin/stdout/stderr, exit codes | 36 tests |
| `test_accuracy.sh` | Microsecond precision, arithmetic correctness, pure Bash validation | 27 tests |

### Infrastructure

| File | Purpose |
|------|---------|
| `test_framework.sh` | Pure Bash assertion functions and test utilities |
| `run_tests.sh` | Test runner with discovery and summary reporting |

**Total: ~155 tests** across 7 test files

## Running Tests

### Run All Tests

```bash
./run_tests.sh
```

### Run Specific Test File

```bash
./run_tests.sh -f test_basic.sh
```

### Verbose Output

```bash
./run_tests.sh -v
```

### Run Individual Test File Directly

```bash
./test_basic.sh
./test_formatting.sh
```

## Test Framework API

The `test_framework.sh` provides pure Bash assertion functions:

### Assertion Functions

```bash
# Compare values for equality
assert_equals <expected> <actual> <test_name>

# Check exit code is 0
assert_success <exit_code> <test_name>

# Check exit code matches expected non-zero value
assert_failure <exit_code> <expected_code> <test_name>

# Check string contains substring
assert_contains <haystack> <needle> <test_name>

# Check string matches regex pattern
assert_matches <string> <pattern> <test_name>

# Check string does not contain substring
assert_not_contains <haystack> <needle> <test_name>
```

### Utility Functions

```bash
# Capture command output (stdout, stderr, exit code separately)
capture_output <var_stdout> <var_stderr> <var_exit_code> <command> [args...]

# Print test summary with pass/fail counts
print_summary

# Reset test counters (for multiple test runs)
reset_counters
```

### Example Usage

```bash
#!/bin/bash
set -euo pipefail

# Load framework
source test_framework.sh

# Load timer
source ../timer

# Run test
capture_output stdout stderr exit_code timer echo "hello"
assert_equals "hello" "$stdout" "Command output preserved"
assert_contains "$stderr" "# timer:" "Timing info in stderr"
assert_success "$exit_code" "Command succeeds"

# Print results
print_summary
```

## Coverage Summary

### Functional Coverage

- ✓ Core timing functionality (EPOCHREALTIME, microsecond precision)
- ✓ Exit status preservation (0, 1, 2, 127, 255, etc.)
- ✓ Output separation (stdout vs stderr)
- ✓ Formatted output (`-f`, `--format` flags)
- ✓ Time unit calculations (days, hours, minutes, seconds)
- ✓ Option parsing (short, long, combined options)
- ✓ Script vs sourced modes
- ✓ Function export and subshell availability
- ✓ errexit preservation (set -e state management)
- ✓ Special characters and quoting
- ✓ stdin/stdout/stderr complexity
- ✓ Edge cases (zero duration, very long durations, empty commands)

### Code Quality Coverage

- ✓ Pure Bash implementation (no awk, bc, grep, date, etc.)
- ✓ Integer arithmetic correctness
- ✓ Printf scientific notation accuracy
- ✓ Time constant validation
- ✓ EPOCHREALTIME format and conversion
- ✓ Base-10 enforcement (octal prevention)
- ✓ Timing accuracy within tolerance
- ✓ Minimal overhead validation

### Error Handling Coverage

- ✓ Missing command arguments
- ✓ Invalid options
- ✓ Failing commands
- ✓ Various exit codes
- ✓ Command not found scenarios
- ✓ Empty/zero values
- ✓ Large values
- ✓ errexit interactions

## Adding New Tests

### Guidelines

1. **Create a new test file**: `test_<feature>.sh`
2. **Use the test framework**: Source `test_framework.sh`
3. **Load timer**: Source `../timer`
4. **Follow BCS**: Use `set -euo pipefail`, proper quoting, etc.
5. **Use descriptive names**: Test names should clearly describe what's being tested
6. **Test one thing**: Each test should verify a single behavior
7. **Call print_summary**: Always end with `print_summary`

### Template

```bash
#!/bin/bash
# Test <feature description>

set -euo pipefail

# Load test framework
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/test_framework.sh"

# Load timer
source "$SCRIPT_DIR/../timer"

echo "${BLUE}Testing: <Feature Name>${RESET}"
echo "======================================"

# Test 1: Description
capture_output stdout stderr exit_code timer echo "test"
assert_equals "test" "$stdout" "Test description"

# Test 2: Description
# ... more tests ...

# Print summary
print_summary

#fin
```

### Best Practices

- **Use capture_output**: Always capture stdout/stderr/exit_code separately
- **Test both success and failure**: Verify correct behavior in both cases
- **Test boundaries**: Edge values, empty inputs, maximum values
- **Verify pure Bash**: Ensure no external commands are used
- **Keep tests fast**: Minimize sleep usage, use calculated values where possible
- **Independent tests**: Each test should be self-contained
- **Clear assertions**: Use descriptive test names that explain expected behavior

## Expected Output

### Successful Test Run

```
======================================
    Timer Test Suite Runner
======================================
Found 7 test files

Running: test_basic
========================================
✓ Timer executes command successfully
✓ Command stdout is preserved
...
✓ All tests passed!

Running: test_formatting
========================================
✓ Formatted output has timer prefix
...
✓ All tests passed!

...

======================================
           FINAL SUMMARY
======================================
All tests passed!

Total Tests:  155
Passed:       155
Failed:       0
======================================
```

### Failed Test Example

```
Running: test_basic
========================================
✓ Timer executes command successfully
✗ Command stdout is preserved
  Expected: "hello world"
  Actual:   "hello"
...

================================
Some tests failed:
  ✗ Command stdout is preserved
--------------------------------
Total:  13
Passed: 12
Failed: 1
================================
```

## Test Development Notes

### Timing Tests

For tests that measure actual timing (e.g., `sleep` commands):
- Use tolerance ranges (e.g., ±20ms for 100ms sleep)
- System load can affect timing precision
- Tests should be robust to minor timing variations

### errexit Tests

Tests involving `set -e` require careful handling:
- Use subshells or functions to isolate state
- Always capture output to prevent early exit
- Verify state preservation explicitly

### Script vs Function Mode

Some tests behave differently in script vs sourced mode:
- Script mode: `-h` shows help, exits
- Function mode: `-h` is noop, command executes
- Tests should verify both modes independently

## Requirements

- **Bash**: 5.2+ (for EPOCHREALTIME)
- **OS**: Any Unix-like system (Linux, macOS, BSD)
- **Permissions**: Execute permission on test files

## Troubleshooting

### Tests fail with "EPOCHREALTIME: unbound variable"

You're running Bash < 5.2. Upgrade to Bash 5.2 or later.

```bash
bash --version
```

### Tests fail with timing accuracy errors

System load can affect timing precision. Try running tests when system is less busy, or adjust tolerance ranges.

### Tests fail with "command not found"

Ensure you're running tests from the `tests/` directory:

```bash
cd /ai/scripts/lib/timer/tests
./run_tests.sh
```

## Contributing

When adding new features to timer:

1. Write tests first (TDD approach)
2. Ensure all existing tests still pass
3. Add new tests for new functionality
4. Update this README with new test file information
5. Maintain 100% Pure Bash principle

## License

Same as timer library - see parent directory for license information.

#fin
