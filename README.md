# DevScope - System Activity and Productivity Analyzer

A comprehensive bash-based system monitoring and productivity analysis tool that collects system metrics, tracks active windows, monitors processes, and provides AI-powered insights using GitHub Copilot CLI.

## Features

- **System Monitoring**: Tracks CPU load, memory usage, uptime
- **Process Monitoring**: Lists top CPU-consuming processes
- **Window Tracking**: Captures active window titles
- **Command History**: Logs recently executed commands with timestamps
- **Daemon Service**: Continuous background collection at configurable intervals
- **Data Aggregation**: JSON-formatted consolidated output
- **Productivity Analysis**: AI-powered insights using GitHub Copilot CLI
- **Automatic Cleanup**: File rotation based on configurable size limits
- **Comprehensive Logging**: Detailed operation logs with error tracking

## Installation

### Prerequisites

The installation script handles dependency installation, but on manual setup you need:

- **Linux OS**: Debian/Ubuntu, Fedora/RHEL/CentOS, or Arch Linux
- **Tools**: `xdotool` or `wmctrl` (for window tracking), `jq` (JSON processing), `curl`
- **Optional**: GitHub CLI (`gh`) for AI-powered analysis

### Quick Install

```bash
sudo ./install.sh
```

The installer will:
1. Detect your Linux distribution
2. Install system dependencies
3. Make all scripts executable
4. Install scripts to `/usr/local/lib/devscope`
5. Create `devscope` command in `/usr/local/bin`
6. Verify installation

After installation, add to your PATH if needed:
```bash
export PATH="/usr/local/bin:$PATH"
```

## Usage

### Core Commands

```bash
# Show help
devscope --help

# Get current active window title
devscope window

# List top 5 CPU consuming processes (JSON format)
devscope processes

# Show last 10 commands with timestamps
devscope commands

# Get current system stats (memory, CPU load, uptime)
devscope stats
```

### Collector Daemon

```bash
# Start the collection daemon (runs every 60 seconds)
devscope collector start

# Check daemon status
devscope collector status

# Stop the daemon
devscope collector stop
```

The daemon:
- Collects data every 60 seconds
- Aggregates all metrics into JSON format
- Stores in `system_data.json`
- Logs operations to `collector.log`
- Auto-rotates files when size limits exceeded:
  - Data files: 50MB limit
  - Log files: 10MB limit

### Productivity Analysis

```bash
# Analyze last 60 entries (default)
devscope analyze

# Analyze last N entries
devscope analyze -n 100

# Show help
devscope analyze --help
```

The analyzer:
- Reads historical data snapshots
- Uses GitHub Copilot CLI to generate insights
- Analyzes patterns in:
  - Active window titles
  - CPU process usage
  - Command history
  - System metrics
- Provides recommendations for productivity improvement
- Saves report to `productivity_analysis.txt`

## Configuration

### Custom Installation Prefix

By default, scripts install to `/usr/local`. To use a custom prefix:

```bash
sudo INSTALL_PREFIX=/opt/devscope ./install.sh
```

### Collector Interval

Edit the collector script to change collection interval:

```bash
# In collector.sh, modify:
INTERVAL=60  # Change to desired seconds
```

### Data/Log Retention

Edit the collector script to change size limits:

```bash
# In collector.sh, modify:
MAX_DATA_SIZE=52428800  # 50MB
MAX_LOG_SIZE=10485760   # 10MB
```

## Output Format

### System Data (JSON)

```json
{
  "timestamp": "2026-02-14T08:12:49Z",
  "data": {
    "window_title": "Terminal Title",
    "top_cpu_processes": {
      "processes": [
        {
          "name": "process_name",
          "cpu_percentage": 15.5
        }
      ]
    },
    "system_stats": {
      "memory": {
        "total_bytes": 16633937920,
        "used_bytes": 15001444352,
        "usage_percent": 90.2
      },
      "cpu": {
        "load_average_1m": 5.91,
        "load_average_5m": 4.30,
        "load_average_15m": 3.56
      },
      "uptime": {
        "total_seconds": 75379,
        "days": 0,
        "hours": 20,
        "minutes": 56
      }
    }
  }
}
```

## Individual Scripts

### get_active_window.sh
Gets the currently active window title using `xdotool` (primary) or `wmctrl` (fallback).

```bash
./get_active_window.sh
```

### top_cpu_processes.sh
Lists top 5 CPU-consuming processes with percentages in JSON format.

```bash
./top_cpu_processes.sh
```

### last_commands_with_timestamps.sh
Reads the last 10 commands from `~/.bash_history` with retrieval timestamps.

```bash
./last_commands_with_timestamps.sh
```

### system_stats.sh
Gathers memory usage, CPU load average, and uptime information.

```bash
./system_stats.sh
```

### collector.sh
Main daemon orchestrating all data collection with logging and cleanup.

```bash
./collector.sh start|stop|status
```

### analyze_productivity.sh
Analyzes collected data using GitHub Copilot CLI for productivity insights.

```bash
./analyze_productivity.sh [-n NUM] [-h]
```

## File Locations

After installation:

- **Scripts**: `/usr/local/lib/devscope/`
- **Binary Command**: `/usr/local/bin/devscope`
- **Data Storage**: `./system_data.json` (working directory)
- **Data History**: `./.data_history/` (working directory)
- **Logs**: `./collector.log` (working directory)
- **Analysis Reports**: `./productivity_analysis.txt` (working directory)

## Troubleshooting

### "xdotool or wmctrl is required"

Install the missing tools:

```bash
# Ubuntu/Debian
sudo apt-get install xdotool wmctrl

# Fedora/RHEL/CentOS
sudo dnf install xdotool wmctrl

# Arch Linux
sudo pacman -S xdotool wmctrl
```

### "GitHub CLI is not installed"

Install GitHub CLI for Copilot analysis:

```bash
# Ubuntu/Debian
sudo apt-get install gh

# Fedora/RHEL/CentOS
sudo dnf install gh

# Arch Linux
sudo pacman -S github-cli
```

### Daemon won't start

Check logs:

```bash
tail -f collector.log
```

Ensure no other instance is running:

```bash
devscope collector status
```

### JSON parsing issues

Validate JSON output:

```bash
devscope stats | jq .
devscope processes | jq .
```

## Performance Considerations

- **Memory**: Each snapshot (~2-5KB), 1,440 per day at 60s interval
- **Disk**: ~50MB limit before rotation, adjust if needed
- **CPU**: Minimal impact, <1% during collection
- **Window tracking**: May fail on some desktop environments (xdotool/wmctrl limitations)

## Security Notes

- History includes command names (be aware of sensitive commands)
- Window titles may contain sensitive information
- Data is stored locally; no cloud transmission
- Runs with user permissions unless started with sudo

## License

Open source - feel free to modify and distribute

## Contributing

Improvements welcome! Areas for enhancement:

- Support for more desktop environments
- Advanced filtering and search
- Long-term trend analysis
- Integration with other productivity tools
- Performance optimizations

---

**Version**: 1.0.0  
**Last Updated**: 2026-02-14
