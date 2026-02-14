#!/bin/bash

set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
BIN_DIR="${INSTALL_PREFIX}/bin"
LIB_DIR="${INSTALL_PREFIX}/lib/devscope"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        log_error "Cannot detect Linux distribution"
        exit 1
    fi
}

# Install dependencies
install_dependencies() {
    log_info "Installing dependencies..."
    
    local distro=$(detect_distro)
    
    case "$distro" in
        ubuntu|debian)
            log_info "Detected Debian/Ubuntu system"
            apt-get update || {
                log_error "Failed to update package lists"
                return 1
            }
            
            local packages="xdotool wmctrl jq curl"
            log_info "Installing packages: $packages"
            apt-get install -y $packages || {
                log_error "Failed to install dependencies"
                return 1
            }
            ;;
        fedora|rhel|centos)
            log_info "Detected Fedora/RHEL/CentOS system"
            
            local packages="xdotool wmctrl jq curl"
            log_info "Installing packages: $packages"
            dnf install -y $packages || {
                log_error "Failed to install dependencies"
                return 1
            }
            ;;
        arch)
            log_info "Detected Arch Linux system"
            
            local packages="xdotool wmctrl jq curl"
            log_info "Installing packages: $packages"
            pacman -Syu --noconfirm $packages || {
                log_error "Failed to install dependencies"
                return 1
            }
            ;;
        *)
            log_warn "Unknown distribution: $distro"
            log_warn "Please install the following packages manually:"
            echo "  - xdotool (for window management)"
            echo "  - wmctrl (fallback window manager)"
            echo "  - jq (JSON processor)"
            echo "  - curl (HTTP client)"
            return 1
            ;;
    esac
    
    log_success "Dependencies installed"
    return 0
}

# Setup directory structure
setup_directories() {
    log_info "Setting up directories..."
    
    if [ ! -d "$BIN_DIR" ]; then
        mkdir -p "$BIN_DIR" || {
            log_error "Failed to create $BIN_DIR"
            return 1
        }
    fi
    
    if [ ! -d "$LIB_DIR" ]; then
        mkdir -p "$LIB_DIR" || {
            log_error "Failed to create $LIB_DIR"
            return 1
        }
    fi
    
    log_success "Directories created"
    return 0
}

# Make scripts executable
make_executable() {
    log_info "Making scripts executable..."
    
    local scripts=(
        "get_active_window.sh"
        "top_cpu_processes.sh"
        "last_commands_with_timestamps.sh"
        "system_stats.sh"
        "collector.sh"
        "analyze_productivity.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            chmod +x "$SCRIPT_DIR/$script" || {
                log_error "Failed to make $script executable"
                return 1
            }
            log_success "Made $script executable"
        else
            log_warn "Script not found: $script"
        fi
    done
    
    return 0
}

# Install scripts to library directory
install_scripts() {
    log_info "Installing scripts to $LIB_DIR..."
    
    local scripts=(
        "get_active_window.sh"
        "top_cpu_processes.sh"
        "last_commands_with_timestamps.sh"
        "system_stats.sh"
        "collector.sh"
        "analyze_productivity.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ]; then
            cp "$SCRIPT_DIR/$script" "$LIB_DIR/$script" || {
                log_error "Failed to install $script"
                return 1
            }
            chmod +x "$LIB_DIR/$script"
            log_success "Installed $script"
        fi
    done
    
    return 0
}

# Create devscope wrapper command
create_wrapper() {
    log_info "Creating devscope wrapper command..."
    
    cat > "$BIN_DIR/devscope" << 'WRAPPER_EOF'
#!/bin/bash

LIB_DIR="@LIB_DIR@"
SCRIPT_DIR="$(pwd)"

# Show usage
show_usage() {
    cat << 'USAGE'
devscope - System Activity and Productivity Analyzer

Usage: devscope <command> [options]

Commands:
    collector start         Start the system data collector daemon
    collector stop          Stop the collector daemon
    collector status        Show collector daemon status
    
    analyze [OPTIONS]       Analyze productivity from collected data
                           Options:
                             -n, --entries NUM   Analyze last N entries (default: 60)
                             -h, --help         Show this help
    
    window                  Get currently active window title
    processes              List top 5 CPU consuming processes
    commands               Show last 10 executed commands
    stats                  Show current system stats
    
    --version              Show version
    --help                 Show this help message

Examples:
    devscope collector start
    devscope analyze -n 100
    devscope stats
USAGE
}

# Parse command
case "$1" in
    collector)
        "$LIB_DIR/collector.sh" "$2"
        ;;
    analyze)
        shift
        "$LIB_DIR/analyze_productivity.sh" "$@"
        ;;
    window)
        "$LIB_DIR/get_active_window.sh"
        ;;
    processes)
        "$LIB_DIR/top_cpu_processes.sh"
        ;;
    commands)
        "$LIB_DIR/last_commands_with_timestamps.sh"
        ;;
    stats)
        "$LIB_DIR/system_stats.sh"
        ;;
    --version)
        echo "devscope v1.0.0"
        ;;
    --help|-h|"")
        show_usage
        ;;
    *)
        echo "Unknown command: $1" >&2
        show_usage
        exit 1
        ;;
esac
WRAPPER_EOF
    
    # Replace LIB_DIR placeholder
    sed -i "s|@LIB_DIR@|$LIB_DIR|g" "$BIN_DIR/devscope"
    
    chmod +x "$BIN_DIR/devscope" || {
        log_error "Failed to make devscope executable"
        return 1
    }
    
    log_success "Created devscope command at $BIN_DIR/devscope"
    return 0
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    local errors=0
    
    # Check if devscope command is in PATH
    if ! command -v devscope &> /dev/null; then
        log_warn "devscope command not found in PATH"
        log_info "Add $BIN_DIR to your PATH by adding to ~/.bashrc or ~/.zshrc:"
        echo "    export PATH=\"$BIN_DIR:\$PATH\""
    else
        log_success "devscope command is in PATH"
    fi
    
    # Check dependencies
    local deps=("xdotool" "wmctrl" "jq")
    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            log_success "$dep is installed"
        else
            log_warn "$dep is not installed"
            errors=$((errors + 1))
        fi
    done
    
    # Test devscope help
    if devscope --help &> /dev/null; then
        log_success "devscope command is working"
    else
        log_warn "devscope command may not be working correctly"
        errors=$((errors + 1))
    fi
    
    return $errors
}

# Main installation flow
main() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  DevScope Installation Script         ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    check_root
    
    log_info "Installation prefix: $INSTALL_PREFIX"
    log_info "Library directory: $LIB_DIR"
    log_info "Binary directory: $BIN_DIR"
    echo ""
    
    # Run installation steps
    install_dependencies || log_warn "Some dependencies may be missing"
    setup_directories || exit 1
    make_executable || exit 1
    install_scripts || exit 1
    create_wrapper || exit 1
    
    echo ""
    log_success "Installation completed!"
    echo ""
    
    verify_installation
    
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "1. Add $BIN_DIR to your PATH if not already there"
    echo "2. Start the collector: devscope collector start"
    echo "3. Wait a few minutes for data collection"
    echo "4. Analyze productivity: devscope analyze"
    echo ""
}

main
