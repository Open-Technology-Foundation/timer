# timer

**100% Pure Bash** high-precision command timer using EPOCHREALTIME with microsecond accuracy.

Zero external dependencies. No awk, no grep, no bc -- just pure, beautiful Bash.

## Features

- 🚀 **100% Pure Bash** - Zero external dependencies for core functionality
- ⏱️  **Microsecond precision** - Uses Bash 5.2+ `EPOCHREALTIME` with integer arithmetic
- 📊 **Human-readable formatting** - Optional days/hours/minutes/seconds output
- 🔧 **Dual mode** - Works as standalone script or sourceable function
- ✅ **Exit status preservation** - Command exit codes are maintained
- 🛡️  **errexit safe** - Preserves caller's `set -e` state
- 🔗 **Combined options** - Supports `-fh`, `-fV`, etc.
- 📤 **Non-intrusive** - Output to stderr, command stdout unaffected
- 🌳 **Subshell ready** - Exported functions work in subshells
- 📝 **BCS compliant** - Follows [BASH-CODING-STANDARD](https://github.com/Open-Technology-Foundation/bash-coding-standard)

## Requirements

- Bash 5.2 or higher (for `EPOCHREALTIME` support)
- **That's it.** No external dependencies.

## Installation

### As a standalone script

```bash
# Make executable
chmod +x timer

# Optionally, copy to a directory in PATH
sudo cp timer /usr/local/bin/
```

### As a sourceable function

```bash
# Add to your .bashrc or .bash_profile:
source /path/to/timer
# or if you have already copied timer into /usr/local/bin:
source timer
# or:
. timer
```

## Usage

### Command Line

```bash
# Time a command (basic output - microsecond precision)
timer sleep 1
# Output: # timer: 1.001034s

# Time with human-readable format
timer -f make -j4
# Output: # timer: 01m 23.456s

# Combined options
timer -fV
# Output: timer 1.0.1

# Show help
timer -h

# Show version
timer -V
```

### As a Sourced Function

```bash
# Source the timer
source timer

# Use in scripts or interactive shell
timer ls -la
timer -f long-running-command

# Options -h and -V are silently ignored (noop) when sourced
timer -h echo "this runs echo, not help"

# Available in subshells
(timer sleep 0.5)

# Exit status is preserved
timer false
echo $?  # Returns 1
```

## Options

| Option | Long Form | Description |
|--------|-----------|-------------|
| `-f` | `--format` | Format output as `Xd XXh XXm X.XXXs` (human-readable) |
| `-h` | `--help` | Display help (script mode) or noop (function mode) |
| `-V` | `--version` | Display version (script mode) or noop (function mode) |

**Combined options supported:** `-fh`, `-fV`, `-hf`, etc.

## Output Format

### Standard Output (6 decimal places)
```
# timer: 1.234567s
```

### Formatted Output (`-f` option, 3 decimal places)
- Seconds only: `0.123s`
- With minutes: `02m 15.456s`
- With hours: `01h 23m 45.678s`
- With days: `2d 13h 45m 10.234s`

## Examples

### Build Timing
```bash
timer -f make clean && make all
```

### Script Performance Testing
```bash
#!/bin/bash
source timer

echo "Processing files..."
timer -f find . -type f -name "*.log" -exec grep "ERROR" {} \;
```

### Exit Status Preservation
```bash
#!/bin/bash
set -e  # Exit on error

timer false && echo "This won't print"
# Script exits with status 1
```

### Benchmark Comparison
```bash
echo "Method 1:"; timer ./method1.sh
echo "Method 2:"; timer ./method2.sh
```

## Known Limitations

### Color Output

Commands using `--color=auto` may not display colors through timer due to TTY detection.

**Workarounds:**
1. Force colors: `timer ls --color=always`
2. Use environment variables: `FORCE_COLOR=1 timer npm test`
3. Use script command: `script -qc "timer ls --color=auto" /dev/null`

## Implementation Details

### Pure Bash Arithmetic Approach

Achieves floating-point precision without external tools:

1. **Convert to integer microseconds:**
   ```bash
   # EPOCHREALTIME: 1234567890.123456
   ${EPOCHREALTIME//./}  # → 1234567890123456 (integer)
   ```

2. **Perform Bash integer arithmetic:**
   ```bash
   elapsed_us=$((end_us - start_us))
   days=$((remaining_us / 86400000000))  # Time constants scaled to microseconds
   ```

3. **Convert back with printf scientific notation:**
   ```bash
   printf "%.6f" "${elapsed_us}e-6"  # → 100.123456
   ```

### Key Implementation Features

- **Zero external dependencies** - No awk, grep, sed, or bc required
- **Microsecond precision** - Uses `EPOCHREALTIME` (Bash 5.2+)
- **Integer arithmetic only** - All calculations use `$(( ))`
- **Time scaling** - Constants multiplied by 1,000,000 (86400 → 86400000000)
- **Printf formatting** - Scientific notation for float output
- **errexit preservation** - Checks and restores `set -e` state
- **Exit status preservation** - Command return codes passed through
- **Pure Bash option splitting** - Combined options split character-by-character
- **Shell quoting** - Uses `${var@Q}` for proper error messages
- **BCS compliant** - Uses `i+=1` instead of `i++`, proper variable declarations
- **Exported functions** - `declare -fx` for subshell availability
- **Stderr output** - Timing info doesn't interfere with command stdout

### Script vs Function Mode

**Script mode:** Early return pattern `[[ "${BASH_SOURCE[0]}" == "$0" ]] || return 0`
- Full option processing with help and version
- `set -euo pipefail` applied safely
- Combined options expanded

**Function mode:**
- Options `-h` and `-V` silently ignored (noop)
- No `set -e` side effects
- Clean function export for immediate use

## Version

**1.0.1** - Pure Bash implementation with zero external dependencies

## License

GPL-3. See LICENSE.

