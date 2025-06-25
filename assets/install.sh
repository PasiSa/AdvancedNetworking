#!/bin/bash

# Simplified Mininet + OpenFlow Install Script
# Fetches from custom forks and provides clean installation

set -e  # Exit on error
set -o nounset  # Exit on unset variables

# Configuration
MININET_REPO="https://github.com/kctong529/mininet.git"
OPENFLOW_REPO="https://github.com/kctong529/openflow.git"
INSTALL_DIR="${HOME}/mininet-dev"
PYTHON="${PYTHON:-python3}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect distribution
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        log_error "Cannot detect OS version"
        exit 1
    fi
    
    log_info "Detected OS: $OS $VER"
    
    # Set package manager commands
    case $OS in
        "Ubuntu"|"Debian"*)
            PKG_UPDATE="sudo apt-get update"
            PKG_INSTALL="sudo DEBIAN_FRONTEND=noninteractive apt-get install -y"
            ;;
        "Fedora"*)
            PKG_UPDATE="sudo dnf check-update || true"
            PKG_INSTALL="sudo dnf install -y"
            ;;
        *)
            log_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

# Install system dependencies
install_dependencies() {
    log_info "Installing system dependencies..."
    
    $PKG_UPDATE
    
    case $OS in
        "Ubuntu"|"Debian"*)
            $PKG_INSTALL \
                git build-essential autoconf automake libtool \
                python3 python3-pip python3-dev python3-setuptools \
                gcc make socat psmisc xterm openssh-client iperf \
                iproute2 net-tools ethtool help2man pkg-config \
                libssl-dev libffi-dev
            ;;
        "Fedora"*)
            $PKG_INSTALL \
                git gcc make autoconf automake libtool \
                python3 python3-pip python3-devel python3-setuptools \
                socat psmisc xterm openssh-clients iperf \
                iproute net-tools ethtool help2man pkgconfig \
                openssl-devel libffi-devel
            ;;
    esac
    
    # Install Python packages
    pip3 install --user pexpect
    
    log_success "System dependencies installed"
}

# Clone repositories
clone_repositories() {
    log_info "Setting up workspace in $INSTALL_DIR"
    
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    # Clone Mininet
    if [ ! -d "mininet" ]; then
        log_info "Cloning Mininet from $MININET_REPO"
        git clone "$MININET_REPO" mininet
    else
        log_info "Updating existing Mininet repository"
        cd mininet && git pull && cd ..
    fi
    
    # Clone OpenFlow
    if [ ! -d "openflow" ]; then
        log_info "Cloning OpenFlow from $OPENFLOW_REPO"
        git clone "$OPENFLOW_REPO" openflow
    else
        log_info "Updating existing OpenFlow repository"
        cd openflow && git pull && cd ..
    fi
    
    log_success "Repositories cloned/updated"
}

# Install OpenFlow
install_openflow() {
    log_info "Installing OpenFlow..."
    
    cd "$INSTALL_DIR/openflow"
    
    # Build OpenFlow
    ./boot.sh
    ./configure
    make -j$(nproc)
    sudo make install
    
    # Update library paths
    sudo ldconfig
    
    log_success "OpenFlow installed"
}

# Install Mininet
install_mininet() {
    log_info "Installing Mininet..."
    
    cd "$INSTALL_DIR/mininet"
    
    # Install Mininet core
    sudo PYTHON="$PYTHON" make install
    
    log_success "Mininet core installed"
}

# Install Open vSwitch
install_openvswitch() {
    log_info "Installing Open vSwitch..."
    
    case $OS in
        "Ubuntu"|"Debian"*)
            $PKG_INSTALL openvswitch-switch openvswitch-common
            
            # Disable controller services (Mininet will manage)
            sudo systemctl stop openvswitch-testcontroller 2>/dev/null || true
            sudo systemctl disable openvswitch-testcontroller 2>/dev/null || true
            ;;
        "Fedora"*)
            $PKG_INSTALL openvswitch
            sudo systemctl enable openvswitch
            sudo systemctl start openvswitch
            ;;
    esac
    
    log_success "Open vSwitch installed"
}

# Install additional tools
install_tools() {
    log_info "Installing additional networking tools..."
    
    # Install POX controller
    cd "$INSTALL_DIR"
    if [ ! -d "pox" ]; then
        git clone https://github.com/noxrepo/pox.git
    fi
    
    # Install Wireshark (optional)
    if command -v apt-get >/dev/null 2>&1; then
        $PKG_INSTALL wireshark-common tshark
    elif command -v dnf >/dev/null 2>&1; then
        $PKG_INSTALL wireshark-cli
    fi
    
    log_success "Additional tools installed"
}

# Configure environment
configure_environment() {
    log_info "Configuring environment..."
    
    # Add paths to bashrc if not already present
    BASHRC="$HOME/.bashrc"
    
    if ! grep -q "MININET_DIR" "$BASHRC"; then
        echo "" >> "$BASHRC"
        echo "# Mininet environment" >> "$BASHRC"
        echo "export MININET_DIR=$INSTALL_DIR/mininet" >> "$BASHRC"
        echo "export OPENFLOW_DIR=$INSTALL_DIR/openflow" >> "$BASHRC"
        echo "export POX_DIR=$INSTALL_DIR/pox" >> "$BASHRC"
        echo "export PATH=\$PATH:\$OPENFLOW_DIR/utilities:\$POX_DIR" >> "$BASHRC"
    fi
    
    log_success "Environment configured"
}

# Test installation
test_installation() {
    log_info "Testing installation..."
    
    # Test Mininet
    if command -v mn >/dev/null 2>&1; then
        log_success "Mininet command available"
    else
        log_error "Mininet command not found"
        return 1
    fi
    
    # Test OpenFlow utilities
    if [ -f "$INSTALL_DIR/openflow/utilities/ovs-controller" ]; then
        log_success "OpenFlow utilities available"
    else
        log_warn "OpenFlow utilities not found at expected location"
    fi
    
    # Test OVS
    if command -v ovs-vsctl >/dev/null 2>&1; then
        log_success "Open vSwitch available"
        sudo ovs-vsctl show
    else
        log_error "Open vSwitch not available"
        return 1
    fi
    
    log_success "Installation test completed"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up temporary files..."
    # Add any cleanup tasks here
    log_success "Cleanup completed"
}

# Usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Simplified Mininet + OpenFlow installation script

OPTIONS:
    -h, --help              Show this help message
    -d, --dir DIR          Set installation directory (default: ~/mininet-dev)
    -m, --mininet-repo URL Set Mininet repository URL
    -o, --openflow-repo URL Set OpenFlow repository URL
    --no-ovs               Skip Open vSwitch installation
    --no-tools             Skip additional tools installation
    --test-only            Only run installation tests
    --clean                Clean up installation directory

EXAMPLES:
    $0                                          # Full installation
    $0 -d /opt/mininet                         # Install to /opt/mininet
    $0 -m https://github.com/myorg/mininet.git # Use custom Mininet repo
    $0 --test-only                             # Test existing installation

EOF
}

# Parse command line arguments
INSTALL_OVS=true
INSTALL_TOOLS=true
TEST_ONLY=false
CLEAN_INSTALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -d|--dir)
            INSTALL_DIR="$2"
            shift 2
            ;;
        -m|--mininet-repo)
            MININET_REPO="$2"
            shift 2
            ;;
        -o|--openflow-repo)
            OPENFLOW_REPO="$2"
            shift 2
            ;;
        --no-ovs)
            INSTALL_OVS=false
            shift
            ;;
        --no-tools)
            INSTALL_TOOLS=false
            shift
            ;;
        --test-only)
            TEST_ONLY=true
            shift
            ;;
        --clean)
            CLEAN_INSTALL=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    log_info "Starting Mininet + OpenFlow installation"
    log_info "Installation directory: $INSTALL_DIR"
    log_info "Mininet repository: $MININET_REPO"
    log_info "OpenFlow repository: $OPENFLOW_REPO"
    
    # Clean installation if requested
    if [ "$CLEAN_INSTALL" = true ]; then
        log_info "Cleaning installation directory..."
        rm -rf "$INSTALL_DIR"
    fi
    
    # Test only mode
    if [ "$TEST_ONLY" = true ]; then
        test_installation
        exit 0
    fi
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        log_error "Do not run this script as root"
        exit 1
    fi
    
    # Main installation steps
    detect_os
    install_dependencies
    clone_repositories
    install_openflow
    install_mininet
    
    if [ "$INSTALL_OVS" = true ]; then
        install_openvswitch
    fi
    
    if [ "$INSTALL_TOOLS" = true ]; then
        install_tools
    fi
    
    configure_environment
    test_installation
    cleanup
    
    log_success "Installation completed successfully!"
    log_info "Please run 'source ~/.bashrc' or restart your terminal to use the new environment"
    log_info "Test with: sudo mn --test pingall"
}

# Run main function
main "$@"