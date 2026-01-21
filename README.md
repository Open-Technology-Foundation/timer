# timer

High-precision command timer with microsecond accuracy.

Pure Bash implementation using `EPOCHREALTIME`. Zero external dependencies.

## Features

- **Microsecond precision** via Bash 5.0+ `EPOCHREALTIME`
- **Three output formats**: raw seconds, human-readable, JSON
- **Dual-mode**: standalone script or sourceable library
- **Exit status preserved**: command return codes pass through
- **errexit safe**: preserves caller's `set -e` state
- **Subshell ready**: exported functions work in subshells

## Requirements

Bash 5.0+ (for `EPOCHREALTIME`)

## Installation

```bash
# Make executable
chmod +x timer

# Copy to PATH (optional)
sudo cp timer /usr/local/bin/
```

## Usage

### Script Mode

```bash
timer sleep 1                    # Basic: 1.001234s
timer -f make -j4                # Formatted: 01m 23.456s
timer -j ./build.sh              # JSON output
timer -o timing.log sleep 1      # Output to file
timer -h                         # Help
timer -V                         # Version
```

### Library Mode

```bash
source timer

timer -f long-running-command
timer false; echo $?             # Exit status preserved (returns 1)
(timer sleep 0.5)                # Works in subshells
```

When sourced, `-h` and `-V` are noops. Unknown options pass to command.

## Options

| Option | Long Form | Description |
|--------|-----------|-------------|
| `-f` | `--format` | Human-readable: `1d 02h 34m 56.789s` |
| `-j` | `--json` | JSON output for scripting |
| `-o` | `--output-to` | Write to FILE (default: stderr) |
| `-h` | `--help` | Show help (script mode only) |
| `-V` | `--version` | Show version (script mode only) |

Combined short options: `-fj` (not with `-o`)

## Output Formats

### Raw (default)
```
# timer: 1.234567s
```

### Formatted (`-f`)
```
0.123s                    # seconds only
02m 15.456s               # with minutes
01h 23m 45.678s           # with hours
2d 13h 45m 10.234s        # with days
```

### JSON (`-j`)
```json
{"elapsed_us":101234,"elapsed_s":0.101234,"elapsed_formatted":"0.101s","exit_code":0,"command":["sleep","0.1"]}
```

## Examples

### Build Timing
```bash
timer -f make clean && timer -f make all
```

### CI/CD Pipeline
```bash
timer -j -o metrics.json ./run-tests.sh
```

### Script Integration
```bash
#!/bin/bash
source timer

echo "Processing..."
timer -f find . -name "*.log" -exec grep "ERROR" {} \;
```

## Implementation

Pure Bash integer arithmetic with no external tools:

```bash
# EPOCHREALTIME → integer µs (remove decimal)
start_us=${EPOCHREALTIME//./}    # 1234567890.123456 → 1234567890123456

# Integer arithmetic
elapsed_us=$((end_us - start_us))

# Back to seconds via scientific notation
printf "%.6f" "${elapsed_us}e-6"  # → 1.234567
```

Time constants scaled to microseconds for integer math:
- 1 day = 86400000000 µs
- 1 hour = 3600000000 µs
- 1 minute = 60000000 µs

## Known Limitations

### Color Output

Commands with `--color=auto` may not display colors (TTY detection).

**Workarounds:**
```bash
timer ls --color=always              # Force colors
FORCE_COLOR=1 timer npm test         # Environment variable
```

## Version

1.2.0

## License

GPL-3. See LICENSE.
