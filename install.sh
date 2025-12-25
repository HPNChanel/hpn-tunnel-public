#!/usr/bin/env bash
################################################################################
#  ____  _____ _   _ ____  ___ _____ _____   ___ _   _ ____ _____  _    _     _     
# |  _ \| ____| \ | |  _ \|_ _|  ___|_   _| |_ _| \ | / ___|_   _|/ \  | |   | |    
# | |_) |  _| |  \| | |_) || || |_    | |    | ||  \| \___ \ | | / _ \ | |   | |    
# |  __/| |___| |\  |  _ < | ||  _|   | |    | || |\  |___) || |/ ___ \| |___| |___ 
# |_|   |_____|_| \_|_| \_\___|_|     |_|   |___|_| \_|____/ |_/_/   \_\_____|_____|
#
# 🚀 Penrift Installer v1.0.3 - BULLDOZER Edition
# 
# Features:
#   - KILLS all running penrift processes before installing
#   - Cleans up ALL old installations
#   - Verifies installed version matches expected
#   - Checksum verification (when available)
#
# Usage:
#   curl -sL penrift.io.vn/install.sh | bash
#
################################################################################

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# ⚙️ CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════
EXPECTED_VERSION="v1.0.7"
REPO="HPNChanel/hpn-tunnel-public"
BINARY_NAME="penrift"
INSTALL_DIR="${PENRIFT_INSTALL_DIR:-/usr/local/bin}"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"

# ══════════════════════════════════════════════════════════════════════════════
# 🎨 COLORS & STYLING
# ══════════════════════════════════════════════════════════════════════════════
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# ══════════════════════════════════════════════════════════════════════════════
# 📝 LOGGING FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✗]${NC} $1"; exit 1; }
step()    { echo -e "${MAGENTA}[→]${NC} $1"; }

# ══════════════════════════════════════════════════════════════════════════════
# 🎨 ASCII ART BANNER
# ══════════════════════════════════════════════════════════════════════════════
print_banner() {
    echo ""
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
    ██████╗ ███████╗███╗   ██╗██████╗ ██╗███████╗████████╗
    ██╔══██╗██╔════╝████╗  ██║██╔══██╗██║██╔════╝╚══██╔══╝
    ██████╔╝█████╗  ██╔██╗ ██║██████╔╝██║█████╗     ██║   
    ██╔═══╝ ██╔══╝  ██║╚██╗██║██╔══██╗██║██╔══╝     ██║   
    ██║     ███████╗██║ ╚████║██║  ██║██║██║        ██║   
    ╚═╝     ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   
EOF
    echo -e "${NC}"
    echo -e "${DIM}    Installer v1.0.3 - BULLDOZER Edition${NC}"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# 💀 BULLDOZER: Kill ALL Running Penrift Processes
# ══════════════════════════════════════════════════════════════════════════════
kill_penrift_processes() {
    step "BULLDOZER: Killing all running Penrift processes..."
    
    # Try pkill first (most common)
    if pkill -9 penrift 2>/dev/null; then
        success "Killed running Penrift process(es)"
    else
        info "No running Penrift processes found (good!)"
    fi
    
    # Also try killall as fallback (macOS prefers this)
    killall -9 penrift 2>/dev/null || true
    
    # Wait for file handles to release
    step "Waiting 2 seconds for file handles to release..."
    sleep 2
    
    # Verify no penrift is running
    if pgrep penrift >/dev/null 2>&1; then
        error "Penrift is still running! Please close it manually and try again."
    fi
    
    success "All Penrift processes terminated"
}

# ══════════════════════════════════════════════════════════════════════════════
# 🔍 SYSTEM DETECTION
# ══════════════════════════════════════════════════════════════════════════════
detect_os() {
    local os
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    
    case "$os" in
        linux*)  echo "linux" ;;
        darwin*) echo "darwin" ;;
        msys*|mingw*|cygwin*) error "Please use install.ps1 for Windows" ;;
        *) error "Unsupported operating system: $os" ;;
    esac
}

detect_arch() {
    local arch
    arch="$(uname -m)"
    
    case "$arch" in
        x86_64|amd64)   echo "amd64" ;;
        aarch64|arm64)  echo "arm64" ;;
        armv7l)         error "ARM v7 is not supported. Please use ARM64 or AMD64." ;;
        i386|i686)      error "32-bit systems are not supported." ;;
        *) error "Unsupported architecture: $arch" ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# 🔧 DEPENDENCY CHECK
# ══════════════════════════════════════════════════════════════════════════════
check_dependencies() {
    local missing=()
    
    command -v curl  >/dev/null 2>&1 || missing+=("curl")
    command -v tar   >/dev/null 2>&1 || missing+=("tar")
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing required tools: ${missing[*]}\n   Install with: sudo apt install ${missing[*]} (Debian/Ubuntu)\n                 brew install ${missing[*]} (macOS)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# 💀 SEARCH & DESTROY - Kill running penrift and clean up old installations
# ══════════════════════════════════════════════════════════════════════════════
cleanup_old_installations() {
    step "Searching for existing Penrift installations..."
    
    local removed=0
    
    # Method 1: Find and remove using 'which' (finds binary in PATH)
    local existing_path
    existing_path=$(which penrift 2>/dev/null || true)
    
    while [ -n "$existing_path" ]; do
        warn "Found existing installation: $existing_path"
        
        if [ -w "$existing_path" ]; then
            rm -f "$existing_path"
            success "Removed: $existing_path"
            ((removed++))
        elif [ -w "$(dirname "$existing_path")" ]; then
            rm -f "$existing_path"
            success "Removed: $existing_path"
            ((removed++))
        else
            warn "Requires sudo to remove: $existing_path"
            if sudo rm -f "$existing_path"; then
                success "Removed: $existing_path (with sudo)"
                ((removed++))
            else
                warn "Could not remove $existing_path - you may need to remove it manually"
            fi
        fi
        
        # Check again for more instances
        existing_path=$(which penrift 2>/dev/null || true)
    done
    
    # Method 2: Check common installation locations
    local common_paths=(
        "$HOME/.local/bin/penrift"
        "$HOME/bin/penrift"
        "/usr/bin/penrift"
        "/usr/local/bin/penrift"
        "/opt/penrift/penrift"
    )
    
    for path in "${common_paths[@]}"; do
        if [ -f "$path" ] && [ "$path" != "${INSTALL_DIR}/${BINARY_NAME}" ]; then
            warn "Found old installation: $path"
            if [ -w "$path" ] || [ -w "$(dirname "$path")" ]; then
                rm -f "$path" && success "Removed: $path" && ((removed++))
            else
                sudo rm -f "$path" 2>/dev/null && success "Removed: $path (sudo)" && ((removed++)) || true
            fi
        fi
    done
    
    # Method 3: Clean up any .old files from failed updates
    find "${INSTALL_DIR}" -name "penrift*.old" -delete 2>/dev/null || true
    find "$HOME" -maxdepth 3 -name "penrift*.old" -delete 2>/dev/null || true
    
    if [ $removed -gt 0 ]; then
        success "Cleaned up $removed old installation(s)"
    else
        info "No old installations found"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# 🌐 GET LATEST VERSION
# ══════════════════════════════════════════════════════════════════════════════
get_latest_version() {
    step "Fetching latest version from GitHub..."
    
    local version
    version=$(curl -fsSL "$API_URL" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ -z "$version" ]; then
        error "Failed to fetch latest version. Check your internet connection."
    fi
    
    success "Latest version: $version"
    echo "$version"
}

# ══════════════════════════════════════════════════════════════════════════════
# 📥 DOWNLOAD & INSTALL
# ══════════════════════════════════════════════════════════════════════════════
install_penrift() {
    local os="$1"
    local arch="$2"
    local version="$3"
    
    local filename="penrift-${os}-${arch}.tar.gz"
    local download_url="https://github.com/${REPO}/releases/download/${version}/${filename}"
    local checksums_url="https://github.com/${REPO}/releases/download/${version}/SHA256SUMS"
    
    # Create temp directory with cleanup trap
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf ${temp_dir}" EXIT
    
    echo ""
    step "Downloading Penrift ${version}..."
    echo -e "   ${DIM}URL: ${download_url}${NC}"
    echo ""
    
    # Download with progress bar
    if ! curl -fSL --progress-bar -o "${temp_dir}/${filename}" "$download_url"; then
        error "Download failed!\n   URL: ${download_url}\n   Check if release exists: https://github.com/${REPO}/releases"
    fi
    
    # Verify file size (basic sanity check)
    local file_size
    file_size=$(stat -f%z "${temp_dir}/${filename}" 2>/dev/null || stat -c%s "${temp_dir}/${filename}" 2>/dev/null || echo "0")
    
    if [ "$file_size" -lt 1000000 ]; then
        error "Downloaded file is too small (${file_size} bytes). Download may be corrupted."
    fi
    
    local file_size_mb
    file_size_mb=$(echo "scale=2; $file_size / 1048576" | bc 2>/dev/null || echo "?")
    success "Downloaded ${filename} (${file_size_mb} MB)"
    
    # Try to verify checksum (optional)
    step "Verifying checksum..."
    if curl -fsSL -o "${temp_dir}/SHA256SUMS" "$checksums_url" 2>/dev/null; then
        local expected_hash actual_hash
        expected_hash=$(grep "$filename" "${temp_dir}/SHA256SUMS" | awk '{print $1}')
        
        if [ -n "$expected_hash" ]; then
            actual_hash=$(sha256sum "${temp_dir}/${filename}" 2>/dev/null | awk '{print $1}' || shasum -a 256 "${temp_dir}/${filename}" | awk '{print $1}')
            
            if [ "$expected_hash" = "$actual_hash" ]; then
                success "Checksum verified ✓"
            else
                warn "Checksum mismatch! Expected: $expected_hash, Got: $actual_hash"
                read -p "Continue anyway? (y/N) " -n 1 -r
                echo
                [[ ! $REPLY =~ ^[Yy]$ ]] && error "Installation aborted."
            fi
        else
            warn "Checksum not found for $filename, skipping verification"
        fi
    else
        warn "Checksum file not available, skipping verification"
    fi
    
    # Extract archive
    step "Extracting archive..."
    tar -xzf "${temp_dir}/${filename}" -C "${temp_dir}"
    
    # Find the binary (might be in subdirectory or root)
    local binary_path
    binary_path=$(find "${temp_dir}" -name "${BINARY_NAME}" -type f | head -1)
    
    if [ -z "$binary_path" ] || [ ! -f "$binary_path" ]; then
        error "Binary '${BINARY_NAME}' not found in archive. Download may be corrupted."
    fi
    
    success "Extracted ${BINARY_NAME}"
    
    # Install to destination
    step "Installing to ${INSTALL_DIR}..."
    
    # Ensure install directory exists
    if [ ! -d "${INSTALL_DIR}" ]; then
        if [ -w "$(dirname "${INSTALL_DIR}")" ]; then
            mkdir -p "${INSTALL_DIR}"
        else
            sudo mkdir -p "${INSTALL_DIR}"
        fi
    fi
    
    # Move binary to install location
    if [ -w "${INSTALL_DIR}" ]; then
        mv "$binary_path" "${INSTALL_DIR}/${BINARY_NAME}"
        chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
    else
        warn "Requires sudo for installation to ${INSTALL_DIR}"
        sudo mv "$binary_path" "${INSTALL_DIR}/${BINARY_NAME}"
        sudo chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
    fi
    
    success "Installed to ${INSTALL_DIR}/${BINARY_NAME}"
}

# ══════════════════════════════════════════════════════════════════════════════
# ✅ VERIFY INSTALLATION
# ══════════════════════════════════════════════════════════════════════════════
verify_installation() {
    local expected_version="$1"
    
    echo ""
    step "Verifying installation..."
    
    # Give system time to update PATH caches
    hash -r 2>/dev/null || true
    
    # Check if binary exists and is executable
    if [ ! -x "${INSTALL_DIR}/${BINARY_NAME}" ]; then
        error "Binary not found or not executable at ${INSTALL_DIR}/${BINARY_NAME}"
    fi
    
    # Try to get version
    local installed_version
    installed_version=$("${INSTALL_DIR}/${BINARY_NAME}" --version 2>/dev/null | head -1 || echo "unknown")
    
    success "Verification complete: ${installed_version}"
    
    # Check if penrift is in PATH
    if command -v penrift >/dev/null 2>&1; then
        local path_binary
        path_binary=$(which penrift)
        
        if [ "$path_binary" = "${INSTALL_DIR}/${BINARY_NAME}" ]; then
            success "penrift is correctly in PATH"
        else
            warn "penrift in PATH ($path_binary) differs from installed location"
        fi
    else
        warn "penrift is not in PATH. Add ${INSTALL_DIR} to your PATH:"
        echo -e "   ${CYAN}echo 'export PATH=\"\$PATH:${INSTALL_DIR}\"' >> ~/.bashrc${NC}"
        echo -e "   ${CYAN}source ~/.bashrc${NC}"
    fi
    
    # ASCII Art Success Message
    echo ""
    echo -e "${GREEN}${BOLD}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║   ██████╗ ███████╗ █████╗ ██████╗ ██╗   ██╗██╗                ║
    ║   ██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝██║                ║
    ║   ██████╔╝█████╗  ███████║██║  ██║ ╚████╔╝ ██║                ║
    ║   ██╔══██╗██╔══╝  ██╔══██║██║  ██║  ╚██╔╝  ╚═╝                ║
    ║   ██║  ██║███████╗██║  ██║██████╔╝   ██║   ██╗                ║
    ║   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝    ╚═╝   ╚═╝                ║
    ║                                                               ║
    ║      🎉 Penrift is ready! Run 'penrift login' to start.       ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo ""
    echo -e "   ${BOLD}Installed Version:${NC} ${expected_version}"
    echo ""
    echo -e "   ${CYAN}${BOLD}Quick Start:${NC}"
    echo -e "   ${DIM}──────────────────────────────${NC}"
    echo -e "   ${GREEN}penrift login${NC}            # Authenticate with your account"
    echo -e "   ${GREEN}penrift http 3000${NC}        # Expose port 3000"
    echo -e "   ${GREEN}penrift http 3000 --id app${NC} # Custom subdomain"
    echo -e "   ${GREEN}penrift update${NC}           # Update to latest version"
    echo -e "   ${GREEN}penrift --help${NC}           # Show all commands"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# 🚀 MAIN ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════
main() {
    print_banner
    
    info "Detecting system..."
    
    local os arch version
    os=$(detect_os)
    arch=$(detect_arch)
    
    success "Detected: ${os}/${arch}"
    
    check_dependencies
    
    # Step 1: BULLDOZER - Kill all running penrift processes
    kill_penrift_processes
    
    # Step 2: Clean up old installations BEFORE installing
    cleanup_old_installations
    
    version=$(get_latest_version)
    
    install_penrift "$os" "$arch" "$version"
    
    verify_installation "$version"
}

# Run main
main "$@"
