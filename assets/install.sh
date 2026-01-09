#!/bin/bash

# ==============================================================================
# Advanced Networking Course - Mininet + OpenFlow Installation Script
# ==============================================================================
#
# PURPOSE:
# This script automates the installation of Mininet, OpenFlow, and related
# networking tools for the Advanced Networking course. It uses maintained
# forks of the original repositories since the upstream versions are no
# longer actively maintained.
#
# WHAT THIS SCRIPT INSTALLS:
# 1. System dependencies (compilers, Python, networking tools)
# 2. OpenFlow reference implementation (software-defined networking protocol)
# 3. Mininet (network emulator for creating virtual networks)
# 4. Open vSwitch (software-based virtual switch)
# 5. Additional tools (POX controller, Wireshark, etc.)
#
# EDUCATIONAL NOTE:
# Each section is clearly marked and explained. Students can modify the
# repository URLs, installation paths, or add their own tools as needed.
#
# ==============================================================================

# ------------------------------------------------------------------------------
# SCRIPT CONFIGURATION AND SAFETY SETTINGS
# ------------------------------------------------------------------------------

# Exit immediately if any command fails (crucial for installation scripts)
set -e

# Exit if any variable is used without being set (prevents silent bugs)
set -o nounset

# Make pipe failures propagate (ensures error detection in command chains)
set -o pipefail

# ------------------------------------------------------------------------------
# GLOBAL CONFIGURATION VARIABLES
# ------------------------------------------------------------------------------
# These variables control the behavior of the installation script.
# Students can modify these to use different repositories or change paths.

# Repository URLs - Using maintained forks instead of abandoned originals
MININET_REPO="https://github.com/PasiSa/mininet.git"
OPENFLOW_REPO="https://github.com/PasiSa/openflow.git"
POX_REPO="https://github.com/noxrepo/pox.git"

# Installation paths
readonly DEFAULT_INSTALL_DIR="${HOME}/mininet-dev"
INSTALL_DIR=""  # Will be set by user input or command line arguments

# Python interpreter to use (allows flexibility for different systems)
PYTHON="${PYTHON:-python3}"

# Package manager commands (will be set based on detected OS)
PKG_UPDATE=""
PKG_INSTALL=""

# OS detection variables
OS=""
VER=""

# ------------------------------------------------------------------------------
# TERMINAL OUTPUT FORMATTING
# ------------------------------------------------------------------------------
# These color codes make the script output more readable and professional.
# Students can modify these or add new ones for custom logging levels.

readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_PURPLE='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_NC='\033[0m'  # No Color (reset)

# ------------------------------------------------------------------------------
# LOGGING FUNCTIONS
# ------------------------------------------------------------------------------
# These functions provide consistent, colored output throughout the script.
# They make it easy to understand what's happening at each step.

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_NC} $1"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_NC} $1"
}

log_warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_NC} $1"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_NC} $1"
}

log_section() {
    echo -e "\n${COLOR_PURPLE}=== $1 ===${COLOR_NC}"
}

log_step() {
    echo -e "${COLOR_CYAN}[STEP]${COLOR_NC} $1"
}

# ------------------------------------------------------------------------------
# RETRY MECHANISM FOR UNRELIABLE OPERATIONS
# ------------------------------------------------------------------------------

# Function: install_with_retry
# Purpose: Execute commands with retry logic for transient failures
# Parameters: $1 - command to execute, $2 - operation description
# Educational note: This shows how to handle network timeouts and temporary failures
install_with_retry() {
    local max_attempts=3
    local attempt=1
    local command="$1"
    local operation_name="$2"

    while [[ $attempt -le $max_attempts ]]; do
        log_info "Attempting $operation_name (attempt $attempt/$max_attempts)"

        # Temporarily disable 'set -e' for this command
        set +e
        eval "$command"
        local exit_code=$?
        set -e

        if [[ $exit_code -eq 0 ]]; then
            log_success "$operation_name completed successfully"
            return 0
        fi

        log_warning "$operation_name failed on attempt $attempt (exit code: $exit_code)"

        if [[ $attempt -lt $max_attempts ]]; then
            local wait_time=$((attempt * 2))  # Exponential backoff: 2s, 4s
            log_info "Waiting ${wait_time}s before retry..."
            sleep $wait_time
        fi

        ((attempt++))
    done

    log_error "$operation_name failed after $max_attempts attempts"
    return 1
}

# ------------------------------------------------------------------------------
# USER INTERACTION FUNCTIONS
# ------------------------------------------------------------------------------

# Function: prompt_install_directory
# Purpose: Interactively ask user where to install the software
# Educational note: This shows how to handle user input validation in bash
prompt_install_directory() {
    log_section "Installation Directory Configuration"

    echo "This script will install Mininet and related tools."
    echo "Choose your installation directory:"
    echo
    echo "1) Default location: $DEFAULT_INSTALL_DIR"
    echo "   (Recommended for most users)"
    echo "2) Custom location: Enter your own path"
    echo
    echo -n "Enter your choice (1-2) [Default: 1]: "

    # Read user input with default fallback
    read -r choice
    choice=${choice:-1}  # If empty, default to 1

    case $choice in
        1)
            INSTALL_DIR="$DEFAULT_INSTALL_DIR"
            log_info "Using default installation directory: $INSTALL_DIR"
            ;;
        2)
            echo -n "Enter your custom installation path: "
            read -r custom_path

            # Handle tilde expansion (~ to home directory)
            custom_path="${custom_path/#\~/$HOME}"

            # Validate the custom path
            if [[ -z "$custom_path" ]]; then
                log_warning "Empty path provided. Using default location."
                INSTALL_DIR="$DEFAULT_INSTALL_DIR"
            else
                INSTALL_DIR="$custom_path"
                log_info "Using custom installation directory: $INSTALL_DIR"
            fi
            ;;
        *)
            log_warning "Invalid choice. Using default location."
            INSTALL_DIR="$DEFAULT_INSTALL_DIR"
            ;;
    esac

    # Validate and create the installation directory
    validate_and_create_directory "$INSTALL_DIR"
}

# Function: validate_and_create_directory
# Purpose: Check if directory exists, warn about conflicts, and create if needed
# Parameter: $1 - Directory path to validate
validate_and_create_directory() {
    local dir_path="$1"

    log_step "Validating installation directory: $dir_path"

    # Check if directory exists and is not empty
    if [[ -d "$dir_path" ]] && [[ -n "$(ls -A "$dir_path" 2>/dev/null)" ]]; then
        log_warning "Directory '$dir_path' already exists and is not empty!"
        echo "This may cause conflicts during installation."
        echo "Existing files will be preserved, but Git operations may fail."
        echo
        echo -n "Do you want to continue anyway? (y/N): "

        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled by user."
            exit 0
        fi
    fi

    # Create directory if it doesn't exist
    if [[ ! -d "$dir_path" ]]; then
        echo -n "Directory doesn't exist. Create '$dir_path'? (Y/n): "
        read -r create_dir
        create_dir=${create_dir:-Y}  # Default to Yes

        if [[ "$create_dir" =~ ^[Yy]$ ]]; then
            if mkdir -p "$dir_path"; then
                log_success "Created directory: $dir_path"
            else
                log_error "Failed to create directory: $dir_path"
                log_error "Please check permissions and try again."
                exit 1
            fi
        else
            log_error "Cannot proceed without a valid installation directory."
            exit 1
        fi
    fi
}

# ------------------------------------------------------------------------------
# SYSTEM DETECTION AND CONFIGURATION
# ------------------------------------------------------------------------------

# Function: detect_operating_system
# Purpose: Identify the Linux distribution and set appropriate package commands
# Educational note: This shows how to handle multiple Linux distributions
detect_operating_system() {
    log_section "Operating System Detection"

    # Primary method: /etc/os-release
    if [[ -f /etc/os-release ]]; then
        # Safely source the file
        if source /etc/os-release 2>/dev/null; then
            OS="${NAME:-Unknown}"
            VER="${VERSION_ID:-Unknown}"
        else
            log_warning "Failed to parse /etc/os-release, trying fallback methods"
            detect_os_fallback
        fi
    else
        detect_os_fallback
    fi

    log_info "Detected: $OS $VER"
    validate_supported_os
}

validate_supported_os() {
    log_step "Validating OS compatibility..."

    case $OS in
        "Ubuntu"|"Debian"*)
            log_success "Supported OS: $OS"
            PKG_UPDATE="sudo apt-get update"
            PKG_INSTALL="sudo DEBIAN_FRONTEND=noninteractive apt-get install -y"
            ;;
        "Fedora"*)
            log_success "Supported OS: $OS"
            PKG_UPDATE="sudo dnf check-update || true"
            PKG_INSTALL="sudo dnf install -y"
            ;;
        "CentOS"*|"Red Hat"*)
            log_success "Supported OS: $OS"
            # Use yum for older versions, dnf for newer
            if command -v dnf >/dev/null 2>&1; then
                PKG_UPDATE="sudo dnf check-update || true"
                PKG_INSTALL="sudo dnf install -y"
            else
                PKG_UPDATE="sudo yum check-update || true"
                PKG_INSTALL="sudo yum install -y"
            fi
            ;;
        *)
            log_error "Unsupported operating system: $OS"
            log_error "This script supports Ubuntu, Debian, Fedora, CentOS, and Red Hat."

            # Provide helpful suggestions
            echo
            log_info "Supported alternatives:"
            echo "  • Ubuntu 18.04+ or Debian 10+"
            echo "  • Fedora 30+"
            echo "  • CentOS 7+ or Red Hat Enterprise Linux 7+"
            echo
            log_info "You may be able to adapt this script by:"
            echo "  • Modifying package manager commands for your distribution"
            echo "  • Installing equivalent packages manually"
            echo "  • Using a supported distribution in a virtual machine"

            return 1
            ;;
    esac

    # Additional version-specific checks
    case $OS in
        "Ubuntu")
            # Check Ubuntu version (require 18.04+)
            if [[ -n "$VER" ]]; then
                local major_ver
                major_ver=$(echo "$VER" | cut -d'.' -f1)
                if [[ $major_ver -lt 18 ]]; then
                    log_warning "Ubuntu $VER detected. Ubuntu 18.04+ recommended."
                    log_warning "Older versions may have compatibility issues."
                fi
            fi
            ;;
        "Debian"*)
            # Check Debian version (require 10+)
            if [[ -n "$VER" ]] && [[ $VER -lt 10 ]]; then
                log_warning "Debian $VER detected. Debian 10+ recommended."
                log_warning "Older versions may lack required packages."
            fi
            ;;
        "CentOS"*)
            # Check CentOS version (require 7+)
            if [[ -n "$VER" ]]; then
                local major_ver
                major_ver=$(echo "$VER" | cut -d'.' -f1)
                if [[ $major_ver -lt 7 ]]; then
                    log_error "CentOS $VER is too old. CentOS 7+ required."
                    return 1
                fi
            fi
            ;;
    esac

    return 0
}

detect_os_fallback() {
    # Fallback detection methods
    if [[ -f /etc/debian_version ]]; then
        OS="Debian"
        VER=$(cat /etc/debian_version)
    elif [[ -f /etc/redhat-release ]]; then
        OS="Red Hat"
        VER=$(cat /etc/redhat-release | cut -d' ' -f3)
    elif command -v lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    else
        log_error "Cannot detect operating system"
        exit 1
    fi
}

# ------------------------------------------------------------------------------
# DEPENDENCY INSTALLATION
# ------------------------------------------------------------------------------

# Function: install_system_dependencies
# Purpose: Install all required system packages for compilation and networking
# Educational note: This shows the extensive dependencies needed for network tools
install_system_dependencies() {
    log_section "System Dependencies Installation"

    # Package repository update with retry (most failure-prone operation)
    log_step "Updating package repositories..."
    install_with_retry "$PKG_UPDATE" "Package repository update" || {
        log_error "Failed to update package repositories after multiple attempts"
        log_error "Please check your internet connection and try again"
        exit 1
    }

    log_step "Installing core development tools and libraries..."

    # Install packages based on operating system
    case $OS in
        "Ubuntu"|"Debian"*)
            log_info "Installing packages for Debian/Ubuntu..."

            # Define package groups for better error isolation
            local -a core_packages=(
                "build-essential"       # Compilation tools (gcc, make, etc.)
                "git"                  # Version control
                "autoconf"             # Auto configuration
                "automake"             # Auto make
                "libtool"              # Library tool
                "pkg-config"           # Needed for configuration (e.g. by OpenFlow)
            )

            local -a python_packages=(
                "python-is-python3"    # Makes 'python' point to python3
                "python3"              # Python interpreter
                "python3-pip"          # Python package installer
                "python3-dev"          # Python development headers
                "python3-pexpect"      # Python pexpect library
                "python3-setuptools"   # Python setup tools
                "python3-venv"         # Python virtual environment
            )

            local -a networking_packages=(
                "socat"                # Socket cat utility
                "psmisc"               # Process utilities
                "xterm"                # Terminal emulator
                "iperf"                # Network performance tool
                "iproute2"             # IP routing utilities
                "net-tools"            # Network tools
                "ethtool"              # Ethernet tool
                "telnet"               # Telnet client
                "openssh-client"       # SSH client
                "iputils-ping"         # Ping utility
            )

            local -a development_packages=(
                "libssl-dev"           # OpenSSL development libraries
                "libffi-dev"           # Foreign function interface library
                "cgroup-tools"         # Control group tools
                "cgroupfs-mount"       # Control group filesystem mounting
                "help2man"             # Help to manual converter
            )

            # Install package groups with retry
            install_with_retry "$PKG_INSTALL ${core_packages[*]}" \
                              "Core development packages" || {
                log_error "Failed to install core development packages"
                exit 1
            }

            install_with_retry "$PKG_INSTALL ${python_packages[*]}" \
                              "Python development packages" || {
                log_error "Failed to install Python packages"
                exit 1
            }

            install_with_retry "$PKG_INSTALL ${networking_packages[*]}" \
                              "Networking utilities" || {
                log_error "Failed to install networking packages"
                exit 1
            }

            install_with_retry "$PKG_INSTALL ${development_packages[*]}" \
                              "Development libraries" || {
                log_error "Failed to install development libraries"
                exit 1
            }
            ;;
        "Fedora"*|"CentOS"*|"Red Hat"*)
            log_info "Installing packages for Red Hat family..."

            # Define Red Hat package groups
            local -a redhat_core=(
                "gcc"                  # C compiler
                "make"                 # Make build tool
                "git"                  # Version control
                "autoconf"             # Auto configuration
                "automake"             # Auto make
                "libtool"              # Library tool
                "pkgconfig"            # Package config
            )

            local -a redhat_python=(
                "python3"              # Python interpreter
                "python3-pip"          # Python package installer
                "python3-devel"        # Python development headers
                "python3-pexpect"      # Python pexpect library
                "python3-setuptools"   # Python setup tools
                "python3-venv"         # Python virtual environment
            )

            local -a redhat_networking=(
                "socat"                # Socket cat utility
                "psmisc"               # Process utilities
                "xterm"                # Terminal emulator
                "iperf"                # Network performance tool
                "iproute"              # IP routing utilities
                "net-tools"            # Network tools
                "ethtool"              # Ethernet tool
                "telnet"               # Telnet client
                "openssh-clients"      # SSH client (different name)
            )

            local -a redhat_development=(
                "openssl-devel"        # OpenSSL development libraries
                "libffi-devel"         # Foreign function interface library
                "help2man"             # Help to manual converter
            )

            # Install Red Hat package groups with retry
            install_with_retry "$PKG_INSTALL ${redhat_core[*]}" \
                              "Core development packages" || {
                log_error "Failed to install core development packages"
                exit 1
            }

            install_with_retry "$PKG_INSTALL ${redhat_python[*]}" \
                              "Python development packages" || {
                log_error "Failed to install Python packages"
                exit 1
            }

            install_with_retry "$PKG_INSTALL ${redhat_networking[*]}" \
                              "Networking utilities" || {
                log_error "Failed to install networking packages"
                exit 1
            }

            install_with_retry "$PKG_INSTALL ${redhat_development[*]}" \
                              "Development libraries" || {
                log_error "Failed to install development libraries"
                exit 1
            }
            ;;
    esac

    # Ensure 'python' command exists (with retry for alternatives command)
    if ! command -v python >/dev/null 2>&1; then
        log_step "Setting 'python' to point to python3 via alternatives..."
        install_with_retry "sudo alternatives --install /usr/bin/python python /usr/bin/python3 1" \
                          "Python alternatives setup" || {
            log_warning "Failed to set python alternatives, but continuing..."
        }
    fi

    log_success "System dependencies installed successfully."
}

# Function: install_python_dependencies
# Purpose: Install required Python packages, handling modern Python environment restrictions
# Educational note: This shows how to handle Python's "externally-managed-environment" error
install_python_dependencies() {
    log_section "Python Dependencies Installation"

    log_step "Verifying Python package availability..."

    # Check if pexpect is available via system packages or already installed
    if check_python_package_availability; then
        log_success "All Python dependencies are available."
        return 0
    fi

    # If system packages didn't work, try alternative methods
    log_warning "System packages may not include all required Python dependencies."
    log_info "Attempting alternative installation methods..."

    # Try different installation approaches in order of preference
    if install_python_via_venv; then
        log_success "Python dependencies installed via virtual environment."
    elif install_python_via_pipx; then
        log_success "Python dependencies installed via pipx."
    elif install_python_with_break_system; then
        log_success "Python dependencies installed with --break-system-packages."
    else
        log_error "Failed to install Python dependencies via all available methods."
        log_error "Please install python3-pexpect manually using your package manager."
        exit 1
    fi
}

# Function: check_python_package_availability
# Purpose: Check if required Python packages are available
check_python_package_availability() {
    log_step "Checking Python package availability..."

    # Test if pexpect can be imported
    if $PYTHON -c "import pexpect; print('pexpect version:', pexpect.__version__)" 2>/dev/null; then
        log_info "Python pexpect library is available via system packages."
        return 0
    else
        log_info "Python pexpect library needs to be installed."
        return 1
    fi
}

# Function: install_python_via_venv
# Purpose: Install Python packages in a virtual environment (recommended approach)
install_python_via_venv() {
    log_step "Attempting Python package installation via virtual environment..."

    local venv_dir="$INSTALL_DIR/python-venv"

    # Create virtual environment
    if $PYTHON -m venv "$venv_dir" 2>/dev/null; then
        log_info "Created virtual environment: $venv_dir"

        # Install packages in virtual environment
        if "$venv_dir/bin/python" -m pip install pexpect; then
            log_info "Installed pexpect in virtual environment."

            # Create a wrapper script for system-wide access
            create_python_wrapper "$venv_dir"
            return 0
        else
            log_warning "Failed to install packages in virtual environment."
            rm -rf "$venv_dir"
            return 1
        fi
    else
        log_warning "Failed to create virtual environment."
        return 1
    fi
}

# Function: create_python_wrapper
# Purpose: Create a wrapper to use the virtual environment Python
create_python_wrapper() {
    local venv_dir="$1"
    local wrapper_script="$INSTALL_DIR/python-wrapper"

    log_step "Creating Python wrapper script..."

    cat > "$wrapper_script" << EOF
#!/bin/bash
# Python wrapper for Mininet installation
# This ensures the virtual environment Python is used
export PATH="$venv_dir/bin:\$PATH"
exec "$venv_dir/bin/python" "\$@"
EOF

    chmod +x "$wrapper_script"

    # Update PYTHON variable to use wrapper
    PYTHON="$wrapper_script"

    log_info "Python wrapper created: $wrapper_script"
}

# Function: install_python_via_pipx
# Purpose: Install Python packages using pipx (if available)
install_python_via_pipx() {
    log_step "Attempting Python package installation via pipx..."

    # Try to install pipx if not available
    if ! command -v pipx >/dev/null 2>&1; then
        log_info "Installing pipx..."
        case $OS in
            "Ubuntu"|"Debian"*)
                if ! eval "$PKG_INSTALL" pipx; then
                    log_warning "Failed to install pipx via package manager."
                    return 1
                fi
                ;;
            "Fedora"*|"CentOS"*|"Red Hat"*)
                if ! eval "$PKG_INSTALL" pipx; then
                    log_warning "Failed to install pipx via package manager."
                    return 1
                fi
                ;;
        esac
    fi

    # Use pipx to install pexpect
    if pipx install pexpect 2>/dev/null; then
        log_info "Installed pexpect via pipx."
        return 0
    else
        log_warning "Failed to install pexpect via pipx."
        return 1
    fi
}

# Function: install_python_with_break_system
# Purpose: Last resort - install with --break-system-packages (with user confirmation)
install_python_with_break_system() {
    log_step "Last resort: attempting installation with --break-system-packages..."

    log_warning "This method may cause conflicts with system packages."
    log_warning "It should only be used if other methods fail."

    # In non-interactive mode, skip this dangerous method
    if [[ "${NON_INTERACTIVE:-false}" == true ]]; then
        log_info "Skipping --break-system-packages in non-interactive mode."
        return 1
    fi

    echo -n "Proceed with --break-system-packages? (y/N): "
    read -r confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "User declined --break-system-packages installation."
        return 1
    fi

    if $PYTHON -m pip install --user --break-system-packages pexpect; then
        log_info "Installed pexpect with --break-system-packages."
        return 0
    else
        log_error "Failed to install pexpect even with --break-system-packages."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# SOURCE CODE MANAGEMENT
# ------------------------------------------------------------------------------

# Function: clone_repositories
# Purpose: Download source code for Mininet and OpenFlow
# Educational note: This shows how to handle Git repositories safely
clone_repositories() {
    log_section "Source Code Repository Management"

    log_step "Setting up workspace in: $INSTALL_DIR"

    # Ensure the installation directory exists
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    # Clone or update Mininet repository
    clone_or_update_repository "mininet" "$MININET_REPO" \
        "Mininet network emulator (maintained fork)"

    # Clone or update OpenFlow repository
    clone_or_update_repository "openflow" "$OPENFLOW_REPO" \
        "OpenFlow reference implementation (maintained fork)"

    log_success "All repositories cloned/updated successfully."
}

# Function: clone_or_update_repository
# Purpose: Clone a new repository or update existing one with retry logic
# Parameters: $1 - directory name, $2 - repository URL, $3 - description
clone_or_update_repository() {
    local dir_name="$1"
    local repo_url="$2"
    local description="$3"

    log_step "Processing repository: $dir_name"
    log_info "Description: $description"

    if [[ ! -d "$dir_name" ]]; then
        log_info "Cloning $dir_name from $repo_url..."

        # Git clone with retry - handles network timeouts and DNS issues
        install_with_retry "git clone '$repo_url' '$dir_name'" \
                          "Cloning $dir_name repository" || {
            log_error "Failed to clone $dir_name repository after multiple attempts"
            log_error "Please check your internet connection and repository URL: $repo_url"
            exit 1
        }

        log_success "Successfully cloned $dir_name repository."
    else
        log_info "Repository $dir_name already exists. Updating..."

        # Git pull with retry - handles network issues during updates
        install_with_retry "(cd '$dir_name' && git pull)" \
                          "Updating $dir_name repository" || {
            log_warning "Failed to update $dir_name repository after multiple attempts"
            log_warning "Continuing with existing version..."
            log_info "You may want to manually update later with: cd $dir_name && git pull"
        }

        log_success "Repository $dir_name processed successfully."
    fi
}

# ------------------------------------------------------------------------------
# OPENFLOW INSTALLATION
# ------------------------------------------------------------------------------

# Function: install_openflow
# Purpose: Compile and install OpenFlow reference implementation with retry logic
# Educational note: This shows the typical autotools build process with error handling
install_openflow() {
    log_section "OpenFlow Reference Implementation Installation"

    log_info "OpenFlow provides the protocol specification and reference tools"
    log_info "for software-defined networking (SDN) communication."

    cd "$INSTALL_DIR/openflow"

    # Step 1: Generate configure script from configure.ac (can fail due to missing tools)
    log_step "Generating build configuration..."
    install_with_retry "./boot.sh" "OpenFlow build configuration generation" || {
        log_error "Failed to generate build configuration"
        log_error "This may indicate missing autotools packages"
        exit 1
    }

    # Step 2: Configure the build system (can fail due to missing dependencies)
    log_step "Configuring build system..."
    install_with_retry "./configure" "OpenFlow build system configuration" || {
        log_error "Failed to configure build system"
        log_error "This may indicate missing development libraries"
        exit 1
    }

    # Step 3: Compile the source code (can fail due to compiler errors)
    log_step "Compiling OpenFlow (this may take a few minutes)..."
    local cpu_cores
    cpu_cores=$(nproc)
    log_info "Using $cpu_cores CPU cores for parallel compilation."

    install_with_retry "make -j$cpu_cores" "OpenFlow compilation" || {
        log_error "OpenFlow compilation failed"
        log_info "Trying single-threaded compilation as fallback..."

        # Fallback to single-threaded compilation
        install_with_retry "make clean && make" "OpenFlow single-threaded compilation" || {
            log_error "OpenFlow compilation failed even with single-threaded build"
            log_error "Please check the compilation errors above"
            exit 1
        }
    }

    # Step 4: Install compiled binaries (can fail due to permission issues)
    log_step "Installing OpenFlow binaries..."
    install_with_retry "sudo make install" "OpenFlow binary installation" || {
        log_error "Failed to install OpenFlow binaries"
        log_error "Please check sudo permissions and disk space"
        exit 1
    }

    # Step 5: Update system library cache (usually reliable, but can fail)
    log_step "Updating system library cache..."
    install_with_retry "sudo ldconfig" "System library cache update" || {
        log_warning "Failed to update library cache, but continuing..."
    }

    log_success "OpenFlow installation completed successfully."
}

# ------------------------------------------------------------------------------
# MININET INSTALLATION
# ------------------------------------------------------------------------------

# Function: install_mininet
# Purpose: Install Mininet network emulator with robust system-wide access setup
# Educational note: This shows how to handle different Python environments and installation paths
install_mininet() {
    log_section "Mininet Network Emulator Installation"

    log_info "Mininet creates realistic virtual networks using Linux namespaces"
    log_info "and virtual ethernet pairs for network experimentation."

    cd "$INSTALL_DIR/mininet"

    # Install Mininet core using its custom Makefile
    log_step "Installing Mininet core..."
    if sudo PYTHON="$PYTHON" make install; then
        log_success "Mininet core installed successfully."
    else
        log_error "Mininet installation failed."
        exit 1
    fi

    # Install Mininet Python module for import access
    log_step "Installing Mininet Python module..."
    log_info "This enables 'from mininet.net import Mininet' in Python scripts"
    if sudo python3 setup.py develop; then
        log_success "Mininet Python module installed successfully."
    else
        log_error "Failed to install Mininet Python module."
        log_warning "You may need to run 'sudo python3 setup.py develop' manually later."
    fi

    # Create system-wide access with robust path detection
    create_mininet_system_access

    log_success "Mininet installation completed successfully."
}

# Function: create_mininet_system_access
# Purpose: Create system-wide access to Mininet command with fallback options
create_mininet_system_access() {
    log_step "Creating system-wide access for Mininet command..."

    local mn_command_found=false
    local mn_source_path=""

    # Array of possible Mininet command locations to check
    local -a possible_mn_paths=(
        "$INSTALL_DIR/mininet/bin/mn"                    # Standard installation
        "$INSTALL_DIR/mininet/mininet-venv/bin/mn"       # Virtual environment installation
        "$INSTALL_DIR/mininet/util/mn"                   # Alternative location
        "/usr/local/bin/mn"                              # System installation
        "/usr/bin/mn"                                    # Package manager installation
    )

    # Find the actual Mininet command location
    log_info "Searching for Mininet command in possible locations..."
    for path in "${possible_mn_paths[@]}"; do
        if [[ -f "$path" && -x "$path" ]]; then
            mn_source_path="$path"
            mn_command_found=true
            log_info "Found Mininet command at: $path"
            break
        fi
    done

    # If not found in expected locations, search more broadly
    if [[ "$mn_command_found" == false ]]; then
        log_info "Mininet command not found in expected locations. Searching..."

        # Search within the installation directory
        local search_result
        search_result=$(find "$INSTALL_DIR/mininet" -name "mn" -type f -executable 2>/dev/null | head -1)

        if [[ -n "$search_result" ]]; then
            mn_source_path="$search_result"
            mn_command_found=true
            log_info "Found Mininet command via search: $search_result"
        fi
    fi

    # Create system-wide access if command was found
    if [[ "$mn_command_found" == true ]]; then
        create_mn_symlink "$mn_source_path"
    else
        provide_manual_access_instructions
    fi
}

# Function: create_mn_symlink
# Purpose: Create symbolic link for Mininet command
# Parameter: $1 - Source path for the mn command
create_mn_symlink() {
    local source_path="$1"
    local target_path="/usr/local/bin/mn"

    log_step "Creating symbolic link for system-wide access..."
    log_info "Source: $source_path"
    log_info "Target: $target_path"

    # Remove existing link if it exists
    if [[ -L "$target_path" ]]; then
        log_info "Removing existing symbolic link..."
        sudo rm -f "$target_path"
    fi

    # Create new symbolic link
    if sudo ln -sf "$source_path" "$target_path"; then
        log_success "Symbolic link created successfully."

        # Verify the link works
        if command -v mn >/dev/null 2>&1; then
            log_success "Mininet command 'mn' is now available system-wide."
        else
            log_warning "Symbolic link created but 'mn' command not found in PATH."
            log_info "You may need to add /usr/local/bin to your PATH."
        fi
    else
        log_warning "Failed to create symbolic link!"
        provide_manual_access_instructions
    fi
}

# Function: provide_manual_access_instructions
# Purpose: Provide manual instructions when automatic system-wide access setup fails
provide_manual_access_instructions() {
    log_warning "Automatic system-wide access setup failed."
    log_info "You can manually access Mininet using one of these methods:"
    echo
    echo "Method 1: Direct path execution"
    echo "  cd $INSTALL_DIR/mininet"
    echo "  sudo ./bin/mn [options]  # or ./util/mn [options]"
    echo
    echo "Method 2: Add to your shell profile"
    echo "  echo 'export PATH=\"$INSTALL_DIR/mininet/bin:\$PATH\"' >> ~/.bashrc"
    echo "  source ~/.bashrc"
    echo
    echo "Method 3: Create your own alias"
    echo "  echo 'alias mn=\"sudo $INSTALL_DIR/mininet/bin/mn\"' >> ~/.bashrc"
    echo "  source ~/.bashrc"
    echo
    echo "Method 4: Python module approach"
    echo "  cd $INSTALL_DIR/mininet"
    echo "  sudo python3 -c \"from mininet.cli import CLI; from mininet.net import Mininet; CLI(Mininet()).cmdloop()\""
    echo
}

# ------------------------------------------------------------------------------
# OPEN VSWITCH INSTALLATION
# ------------------------------------------------------------------------------

# Function: install_openvswitch
# Purpose: Install Open vSwitch virtual switching software
# Educational note: This shows different approaches for different Linux distributions
install_openvswitch() {
    log_section "Open vSwitch Installation"

    log_info "Open vSwitch is a production-quality virtual switch"
    log_info "that supports OpenFlow for software-defined networking."

    case $OS in
        "Ubuntu"|"Debian"*)
            install_ovs_debian
            ;;
        "Fedora"*|"CentOS"*|"Red Hat"*)
            install_ovs_redhat
            ;;
    esac

    log_success "Open vSwitch installation completed."
}

# Function: install_ovs_debian
# Purpose: Install Open vSwitch on Debian/Ubuntu systems
install_ovs_debian() {
    log_step "Installing Open vSwitch packages for Debian/Ubuntu..."

    eval "$PKG_INSTALL" openvswitch-switch openvswitch-common

    # Disable the test controller service (Mininet will manage switches)
    log_step "Configuring Open vSwitch services..."

    # Stop and disable test controller (if it exists)
    if sudo systemctl stop openvswitch-testcontroller 2>/dev/null; then
        log_info "Stopped OpenFlow test controller service."
    fi

    if sudo systemctl disable openvswitch-testcontroller 2>/dev/null; then
        log_info "Disabled OpenFlow test controller service."
    fi

    log_success "Open vSwitch configured for Debian/Ubuntu."
}

# Function: install_ovs_redhat
# Purpose: Install Open vSwitch on Red Hat family systems
install_ovs_redhat() {
    log_step "Installing Open vSwitch packages for Red Hat family..."

    eval "$PKG_INSTALL" openvswitch

    # Enable and start the Open vSwitch service
    log_step "Enabling Open vSwitch service..."

    if sudo systemctl enable openvswitch; then
        log_success "Open vSwitch service enabled."
    else
        log_warning "Failed to enable Open vSwitch service."
    fi

    if sudo systemctl start openvswitch; then
        log_success "Open vSwitch service started."
    else
        log_warning "Failed to start Open vSwitch service."
    fi

    log_success "Open vSwitch configured for Red Hat family."
}

# ------------------------------------------------------------------------------
# ADDITIONAL TOOLS INSTALLATION
# ------------------------------------------------------------------------------

# Function: install_additional_tools
# Purpose: Install supplementary networking and development tools
install_additional_tools() {
    log_section "Additional Networking Tools Installation"

    log_info "Installing supplementary tools for network development and analysis..."

    # Install POX SDN controller
    install_pox_controller

    # Install Wireshark for packet analysis
    install_wireshark

    log_success "Additional tools installation completed."
}

# Function: install_pox_controller
# Purpose: Install POX SDN controller for OpenFlow experiments with retry logic
install_pox_controller() {
    log_step "Installing POX SDN controller..."

    cd "$INSTALL_DIR"

    # Clone POX repository if not present
    if [[ ! -d "pox" ]]; then
        log_info "Cloning POX controller from $POX_REPO..."

        install_with_retry "git clone '$POX_REPO'" "POX controller cloning" || {
            log_error "Failed to clone POX controller after multiple attempts"
            log_error "Please check your internet connection and repository URL: $POX_REPO"
            return 1
        }

        log_success "POX controller cloned successfully."
    else
        log_info "POX controller already present. Updating..."

        install_with_retry "(cd pox && git pull)" "POX controller update" || {
            log_warning "Failed to update POX controller after multiple attempts"
            log_warning "Continuing with existing version..."
        }
    fi

    log_info "POX controller available at: $INSTALL_DIR/pox"
}

# Function: install_wireshark
# Purpose: Install Wireshark packet analyzer
install_wireshark() {
    log_step "Installing Wireshark packet analyzer..."

    case $OS in
        "Ubuntu"|"Debian"*)
            if eval "$PKG_INSTALL" wireshark-common tshark; then
                log_success "Wireshark installed successfully."
            else
                log_warning "Failed to install Wireshark."
            fi
            ;;
        "Fedora"*|"CentOS"*|"Red Hat"*)
            if eval "$PKG_INSTALL" wireshark-cli; then
                log_success "Wireshark CLI installed successfully."
            else
                log_warning "Failed to install Wireshark CLI."
            fi
            ;;
    esac
}

# ------------------------------------------------------------------------------
# ENVIRONMENT CONFIGURATION
# ------------------------------------------------------------------------------

# Function: configure_environment
# Purpose: Set up environment variables and PATH for easy tool access
configure_environment() {
    log_section "Environment Configuration"

    log_step "Configuring shell environment..."

    local bashrc="$HOME/.bashrc"
    local env_marker="# Advanced Networking Course - Mininet Environment"

    # Check if environment is already configured
    if grep -q "$env_marker" "$bashrc"; then
        log_info "Environment already configured in $bashrc."
        return 0
    fi

    # Add environment configuration to .bashrc
    log_step "Adding environment variables to $bashrc..."

    cat << EOF >> "$bashrc"

$env_marker
# These variables provide easy access to networking tools installed for the course
export MININET_DIR="$INSTALL_DIR/mininet"
export OPENFLOW_DIR="$INSTALL_DIR/openflow"
export POX_DIR="$INSTALL_DIR/pox"

# Add tool directories to PATH for easy command access
export PATH="\$PATH:\$OPENFLOW_DIR/utilities:\$POX_DIR"

# Aliases for common networking commands
alias mn-help='mn --help'
alias mn-test='sudo mn --test pingall'
alias ovs-show='sudo ovs-vsctl show'
alias pox-help='cd \$POX_DIR && python3 pox.py --help'
EOF

    log_success "Environment configuration added to $bashrc."
    log_info "Run 'source ~/.bashrc' or restart your terminal to apply changes."
}

# ------------------------------------------------------------------------------
# INSTALLATION TESTING
# ------------------------------------------------------------------------------

# Function: test_installation
# Purpose: Verify that all components are installed and working correctly
test_installation() {
    log_section "Installation Testing and Verification"

    log_info "Running comprehensive installation tests..."

    local test_passed=true

    # Test 1: Mininet command availability
    if test_mininet_command; then
        log_success "✓ Mininet command test passed"
    else
        log_error "✗ Mininet command test failed"
        test_passed=false
    fi

    # Test 1b: Mininet Python module availability
    if test_mininet_python_module; then
        log_success "✓ Mininet Python module test passed"
    else
        log_error "✗ Mininet Python module test failed"
        test_passed=false
    fi

    # Test 2: OpenFlow utilities
    if test_openflow_utilities; then
        log_success "✓ OpenFlow utilities test passed"
    else
        log_warning "⚠ OpenFlow utilities test had issues"
    fi

    # Test 3: Open vSwitch
    if test_openvswitch; then
        log_success "✓ Open vSwitch test passed"
    else
        log_error "✗ Open vSwitch test failed"
        test_passed=false
    fi

    # Test 4: POX controller
    if test_pox_controller; then
        log_success "✓ POX controller test passed"
    else
        log_warning "⚠ POX controller test had issues"
    fi

    # Test 5: Python dependencies
    if test_python_dependencies; then
        log_success "✓ Python dependencies test passed"
    else
        log_error "✗ Python dependencies test failed"
        test_passed=false
    fi

    # Overall test result
    if [[ "$test_passed" == true ]]; then
        log_success "✓ All critical tests passed! Installation is ready for use."
    else
        log_error "✗ Some critical tests failed. Please review the errors above."
        return 1
    fi
}

# Function: test_mininet_command
# Purpose: Test if Mininet command is available and functional
test_mininet_command() {
    log_step "Testing Mininet command availability..."

    if command -v mn >/dev/null 2>&1; then
        log_info "Mininet command found: $(which mn)"
        return 0
    else
        log_error "Mininet command 'mn' not found in PATH"
        return 1
    fi
}

# Function: test_mininet_python_module
# Purpose: Test if Mininet Python module can be imported
test_mininet_python_module() {
    log_step "Testing Mininet Python module availability..."

    if python3 -c "from mininet.net import Mininet; from mininet.node import OVSKernelSwitch; print('Mininet Python module is available')" 2>/dev/null; then
        log_info "Mininet Python module can be imported successfully"
        return 0
    else
        log_error "Failed to import Mininet Python module"
        log_error "You may need to run: cd $INSTALL_DIR/mininet && sudo python3 setup.py develop"
        return 1
    fi
}

# Function: test_openflow_utilities
# Purpose: Test OpenFlow reference implementation utilities
test_openflow_utilities() {
    log_step "Testing OpenFlow utilities..."

    local openflow_controller="/usr/local/bin/controller"

    if [[ -f "$openflow_controller" ]]; then
        log_info "OpenFlow controller found: $openflow_controller"
        return 0
    else
        log_warning "OpenFlow controller not found at expected location"
        return 1
    fi
}

# Function: test_openvswitch
# Purpose: Test Open vSwitch installation and basic functionality
test_openvswitch() {
    log_step "Testing Open vSwitch..."

    if command -v ovs-vsctl >/dev/null 2>&1; then
        log_info "Open vSwitch command found: $(which ovs-vsctl)"

        # Test basic OVS functionality
        if sudo ovs-vsctl show >/dev/null 2>&1; then
            log_info "Open vSwitch is responding to commands"
            return 0
        else
            log_warning "Open vSwitch installed but not responding properly"
            return 1
        fi
    else
        log_error "Open vSwitch command 'ovs-vsctl' not found"
        return 1
    fi
}

# Function: test_pox_controller
# Purpose: Test POX SDN controller installation
test_pox_controller() {
    log_step "Testing POX controller..."

    local pox_path="$INSTALL_DIR/pox"

    if [[ -d "$pox_path" ]] && [[ -f "$pox_path/pox.py" ]]; then
        log_info "POX controller found: $pox_path"

        # Test if POX can be executed
        if cd "$pox_path" && python3 pox.py --help >/dev/null 2>&1; then
            log_info "POX controller is functional"
            return 0
        else
            log_warning "POX controller found but may have issues"
            return 1
        fi
    else
        log_warning "POX controller not found at expected location"
        return 1
    fi
}

# Function: test_python_dependencies
# Purpose: Test if required Python packages are available
test_python_dependencies() {
    log_step "Testing Python dependencies..."

    # Test pexpect import
    if $PYTHON -c "import pexpect; print('pexpect version:', pexpect.__version__)" 2>/dev/null; then
        log_info "Python pexpect library is available"
        return 0
    else
        log_error "Python pexpect library is not available"
        return 1
    fi
}

# Function: run_basic_mininet_test
# Purpose: Run a basic Mininet functionality test (optional)
run_basic_mininet_test() {
    log_step "Running basic Mininet functionality test..."

    log_info "This will create a simple network topology and test connectivity"
    echo -n "Run Mininet test? This requires sudo privileges (y/N): "
    read -r run_test

    if [[ "$run_test" =~ ^[Yy]$ ]]; then
        log_info "Running: sudo mn --test pingall"
        if sudo mn --test pingall; then
            log_success "Mininet basic test completed successfully"
        else
            log_error "Mininet basic test failed"
            return 1
        fi
    else
        log_info "Skipping Mininet functionality test"
    fi
}

# ------------------------------------------------------------------------------
# CLEANUP AND MAINTENANCE
# ------------------------------------------------------------------------------

# Function: cleanup_installation
# Purpose: Clean up temporary files and perform post-installation tasks
cleanup_installation() {
    log_section "Post-Installation Cleanup"

    log_step "Performing cleanup tasks..."

    # Clear package manager cache (optional)
    case $OS in
        "Ubuntu"|"Debian"*)
            if sudo apt-get autoremove -y >/dev/null 2>&1; then
                log_info "Removed unnecessary packages"
            fi
            ;;
        "Fedora"*|"CentOS"*|"Red Hat"*)
            if sudo dnf autoremove -y >/dev/null 2>&1 || sudo yum autoremove -y >/dev/null 2>&1; then
                log_info "Removed unnecessary packages"
            fi
            ;;
    esac

    # Update locate database for file searching
    if command -v updatedb >/dev/null 2>&1; then
        log_step "Updating file location database..."
        sudo updatedb 2>/dev/null || true
    fi

    log_success "Cleanup completed"
}

# Function: display_installation_summary
# Purpose: Show final installation summary and usage instructions
display_installation_summary() {
    log_section "Installation Summary"

    echo
    echo "🎉 Advanced Networking Course - Mininet Installation Complete!"
    echo
    echo "Installation Location:"
    echo "   $INSTALL_DIR"
    echo
    echo "Installed Components:"
    echo "   ✓ Mininet Network Emulator"
    echo "   ✓ OpenFlow Reference Implementation"
    echo "   ✓ Open vSwitch Virtual Switch"
    echo "   ✓ POX SDN Controller"
    echo "   ✓ Python Dependencies (pexpect)"
    echo "   ✓ Wireshark Packet Analyzer"
    echo
    echo "Quick Start Commands:"
    echo "   # Apply environment changes"
    echo "   source ~/.bashrc"
    echo
    echo "   # Test basic Mininet functionality"
    echo "   sudo mn --test pingall"
    echo
    echo "   # Create a simple 2-host network"
    echo "   sudo mn --topo single,2"
    echo
    echo "   # View Open vSwitch configuration"
    echo "   sudo ovs-vsctl show"
    echo
    echo "   # Start POX controller (in separate terminal)"
    echo "   cd $INSTALL_DIR/pox && python3 pox.py forwarding.l2_learning"
    echo
    echo "Useful Resources:"
    echo "   • Mininet Walkthrough: http://mininet.org/walkthrough/"
    echo "   • OpenFlow Tutorial: https://github.com/mininet/openflow-tutorial"
    echo "   • POX Documentation: https://noxrepo.github.io/pox-doc/"
    echo
    echo "Important Notes:"
    echo "   • Most Mininet commands require sudo privileges"
    echo "   • Always clean up networks with 'sudo mn -c' after experiments"
    echo "   • Environment variables are set in ~/.bashrc"
    echo
    echo "Troubleshooting:"
    echo "   • If 'mn' command not found: source ~/.bashrc or restart terminal"
    echo "   • If OVS issues: sudo systemctl restart openvswitch-switch"
    echo "   • For permission errors: ensure your user is in sudo group"
    echo
}

# ------------------------------------------------------------------------------
# COMMAND LINE ARGUMENT PARSING
# ------------------------------------------------------------------------------

# Function: display_help
# Purpose: Show usage information and available options
display_help() {
    cat << EOF
Advanced Networking Course - Mininet Installation Script

USAGE:
    $0 [OPTIONS]

DESCRIPTION:
    This script installs Mininet, OpenFlow, and related networking tools for
    the Advanced Networking course. It uses maintained forks of the original
    repositories and provides a clean, educational installation process.

OPTIONS:
    -h, --help              Show this help message and exit
    -d, --dir DIR           Set custom installation directory
                           (default: $DEFAULT_INSTALL_DIR)
    -m, --mininet-repo URL  Set custom Mininet repository URL
                           (default: $MININET_REPO)
    -o, --openflow-repo URL Set custom OpenFlow repository URL
                           (default: $OPENFLOW_REPO)
    --no-ovs               Skip Open vSwitch installation
    --no-tools             Skip additional tools (POX, Wireshark)
    --test-only            Only run installation tests (no installation)
    --clean                Clean installation directory before installing
    --non-interactive      Run without user prompts (use defaults)

EXAMPLES:
    # Standard installation with interactive prompts
    $0

    # Install to custom directory
    $0 --dir /opt/mininet

    # Use custom repository (e.g., your own fork)
    $0 --mininet-repo https://github.com/yourusername/mininet.git

    # Minimal installation without additional tools
    $0 --no-tools

    # Test existing installation
    $0 --test-only

    # Clean installation (removes existing files)
    $0 --clean --dir /tmp/mininet-test

    # Automated installation for scripts
    $0 --non-interactive --dir /opt/mininet

EDUCATIONAL NOTES:
    • This script is designed for learning - each section is well-commented
    • Students can modify repository URLs to use their own forks
    • The script handles multiple Linux distributions automatically
    • All components are installed from source for educational purposes
    • Error handling demonstrates best practices for bash scripting

REQUIREMENTS:
    • Linux system (Ubuntu, Debian, Fedora, CentOS, or Red Hat)
    • Internet connection for downloading packages and source code
    • Sudo privileges for system package installation
    • At least 2GB free disk space for full installation

SUPPORT:
    For issues or questions, please refer to the course documentation
    or contact your instructor.

EOF
}

# Function: parse_command_line_arguments
# Purpose: Process command line options and set global variables
parse_command_line_arguments() {
    # Initialize option flags
    local install_ovs=true
    local install_tools=true
    local test_only=false
    local clean_install=false
    local non_interactive=false
    local dir_from_cmdline=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                display_help
                exit 0
                ;;
            -d|--dir)
                if [[ -n "$2" && "$2" != -* ]]; then
                    INSTALL_DIR="$2"
                    dir_from_cmdline=true
                    shift 2
                else
                    log_error "Option --dir requires a directory path"
                    exit 1
                fi
                ;;
            -m|--mininet-repo)
                if [[ -n "$2" && "$2" != -* ]]; then
                    MININET_REPO="$2"
                    shift 2
                else
                    log_error "Option --mininet-repo requires a repository URL"
                    exit 1
                fi
                ;;
            -o|--openflow-repo)
                if [[ -n "$2" && "$2" != -* ]]; then
                    OPENFLOW_REPO="$2"
                    shift 2
                else
                    log_error "Option --openflow-repo requires a repository URL"
                    exit 1
                fi
                ;;
            --no-ovs)
                install_ovs=false
                shift
                ;;
            --no-tools)
                install_tools=false
                shift
                ;;
            --test-only)
                test_only=true
                shift
                ;;
            --clean)
                clean_install=true
                shift
                ;;
            --non-interactive)
                non_interactive=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Set global variables based on parsed options
    export INSTALL_OVS="$install_ovs"
    export INSTALL_TOOLS="$install_tools"
    export TEST_ONLY="$test_only"
    export CLEAN_INSTALL="$clean_install"
    export NON_INTERACTIVE="$non_interactive"
    export DIR_FROM_CMDLINE="$dir_from_cmdline"
}

# ------------------------------------------------------------------------------
# MAIN EXECUTION FUNCTION
# ------------------------------------------------------------------------------

# Function: main
# Purpose: Orchestrate the entire installation process
main() {
    # Display welcome message
    log_section "Advanced Networking Course - Mininet Installation"
    log_info "This script will install Mininet, OpenFlow, and related networking tools"
    log_info "for hands-on software-defined networking experiments."
    echo

    # Parse command line arguments
    parse_command_line_arguments "$@"

    # Determine installation directory
    if [[ "$DIR_FROM_CMDLINE" == true ]]; then
        log_info "Using command-line specified directory: $INSTALL_DIR"
        validate_and_create_directory "$INSTALL_DIR"
    elif [[ "$NON_INTERACTIVE" == true ]]; then
        INSTALL_DIR="$DEFAULT_INSTALL_DIR"
        log_info "Using default directory (non-interactive mode): $INSTALL_DIR"
        validate_and_create_directory "$INSTALL_DIR"
    else
        prompt_install_directory
    fi

    # Display configuration summary
    log_section "Installation Configuration"
    log_info "Installation directory: $INSTALL_DIR"
    log_info "Mininet repository: $MININET_REPO"
    log_info "OpenFlow repository: $OPENFLOW_REPO"
    log_info "Install Open vSwitch: $INSTALL_OVS"
    log_info "Install additional tools: $INSTALL_TOOLS"
    echo

    # Clean installation if requested
    if [[ "$CLEAN_INSTALL" == true ]]; then
        log_info "Cleaning installation directory..."
        rm -rf "$INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
        log_success "Installation directory cleaned"
    fi

    # Test-only mode
    if [[ "$TEST_ONLY" == true ]]; then
        log_info "Running in test-only mode..."
        test_installation
        exit $?
    fi

    # Security check - don't run as root
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root!"
        log_error "It will use sudo when needed for specific operations."
        log_error "Please run as a regular user with sudo privileges."
        exit 1
    fi

    # Main installation sequence
    log_section "Starting Installation Process"

    # Phase 1: System preparation
    detect_operating_system
    install_system_dependencies
    install_python_dependencies

    # Phase 2: Source code management
    clone_repositories

    # Phase 3: Core networking tools
    install_openflow
    install_mininet

    # Phase 4: Optional components
    if [[ "$INSTALL_OVS" == true ]]; then
        install_openvswitch
    else
        log_info "Skipping Open vSwitch installation (--no-ovs specified)"
    fi

    if [[ "$INSTALL_TOOLS" == true ]]; then
        install_additional_tools
    else
        log_info "Skipping additional tools installation (--no-tools specified)"
    fi

    # Phase 5: Configuration and testing
    configure_environment
    test_installation

    # Optional basic functionality test
    if [[ "$NON_INTERACTIVE" != true ]]; then
        run_basic_mininet_test
    fi

    # Phase 6: Cleanup and summary
    cleanup_installation
    display_installation_summary

    log_success "Installation completed successfully!"
    log_info "Happy networking!"
}

# ------------------------------------------------------------------------------
# SCRIPT ENTRY POINT
# ------------------------------------------------------------------------------

# Trap for cleanup on script exit or interruption
trap cleanup_installation EXIT

# Run main function with all command line arguments
main "$@"