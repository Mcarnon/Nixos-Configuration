#!/usr/bin/env bash
#==============================================================================
# NixOS Installation Script (合并 disko + 配置生成 + nixos-install)
#
# Usage:
#   git clone <repo-url> Nixos-Configuration && cd Nixos-Configuration
#   $EDITOR hosts/laptop/disko-fs.nix  # 修改 device
#   chmod +x scripts/install.sh && sudo ./scripts/install.sh
#
# Flow:
#   - Enable nix-command and flakes (live env may not have them)
#   - Run disko (interactive - you will set LUKS password)
#   - Copy repo to /mnt/etc/nixos (persist config)
#   - Generate hardware config and move to hosts/laptop/
#   - Prompt to edit LUKS/ESP UUIDs
#   - Run nixos-install
#==============================================================================

set -eo pipefail  # Note: removed 'u' because we use unbound variables intentionally in some places

# Color output (English messages for live USB)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
section() { echo -e "${CYAN}==== $* ====${NC}"; }

# Pause for user to check output
pause() {
    local prompt="${1:-Press Enter to continue...}"
    read -p "$prompt" </dev/tty
}

#==============================================================================
# Check if running as root
#==============================================================================
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Please run this script with sudo"
        exit 1
    fi
}

#==============================================================================
# Check nix is available and enable flakes
#==============================================================================
setup_nix() {
    info "Checking Nix..."
    if ! nix --version &>/dev/null; then
        error "Nix is not installed"
        exit 1
    fi
    # Export nix config with experimental features
    export NIX_CONFIG='experimental-features = nix-command flakes'
    info "Nix ready with flakes enabled"
}

#==============================================================================
# Check and display disk device from disko config
#==============================================================================
check_disk() {
    local disko_file="$1"
    info "Checking disko config: $disko_file"

    if [[ ! -f "$disko_file" ]]; then
        error "Disko config not found: $disko_file"
        exit 1
    fi

    # Extract device from disko config
    local device
    device=$(grep -o 'device = "[^"]*"' "$disko_file" | head -1 | cut -d'"' -f2)
    if [[ -z "$device" ]]; then
        error "Cannot find device in $disko_file"
        exit 1
    fi

    info "Target disk: $device"
    warn "ALL DATA ON THIS DISK WILL BE DESTROYED!"
    echo ""
    lsblk -o NAME,SIZE,TYPE "$device" 2>/dev/null || true
    echo ""
}

#==============================================================================
# Run disko (interactive - user will set LUKS password inside disko)
#==============================================================================
run_disko() {
    local disko_file="$1"
    section "Disko: Partition, Format, Mount"
    info "This will:"
    info "  1. Wipe the disk and create partitions"
    info "  2. Set up LUKS encryption (you'll be asked for a password - REMEMBER IT!)"
    info "  3. Create btrfs subvolumes and mount everything"
    echo ""
    info "Starting disko..."
    info "When asked 'Do you want to continue?', type 'y' to proceed"
    echo ""

    # Run disko - it has its own interactive prompts
    # Don't use 'set -e' behavior here - let disko handle its own errors
    NIX_CONFIG='experimental-features = nix-command flakes' \
        nix run github:nix-community/disko/latest -- \
        --mode destroy,format,mount "$disko_file"
    local disko_exit=$?

    if [[ $disko_exit -ne 0 ]]; then
        error "Disko failed with exit code $disko_exit"
        exit 1
    fi

    success "Disko completed successfully"
}

#==============================================================================
# Copy repo to /mnt/etc/nixos for persistence
#==============================================================================
copy_repo() {
    section "Copying Repository"
    local repo_path
    repo_path="$(cd "$(dirname "$0")/.." && pwd)"
    local mnt_etc_nixos="/mnt/etc/nixos"

    info "Repository: $repo_path"
    info "Destination: $mnt_etc_nixos"

    # Check /mnt is mounted
    if ! mountpoint -q /mnt 2>/dev/null; then
        error "/mnt is not mounted. Did disko succeed?"
        exit 1
    fi

    # Copy repo (excluding .git to save space/time)
    info "Copying repo (excluding .git)..."
    mkdir -p "$mnt_etc_nixos"
    rsync -av --exclude='.git' "$repo_path/" "$mnt_etc_nixos/"

    success "Repository copied"
}

#==============================================================================
# Generate hardware config
#==============================================================================
generate_config() {
    section "Generating Hardware Configuration"
    local mnt_etc_nixos="/mnt/etc/nixos"
    local repo_name
    repo_name="$(basename "$(cd "$(dirname "$0")/.." && pwd)")"
    local mnt_repo="$mnt_etc_nixos/$repo_name"

    info "Generating hardware config in $mnt_repo..."
    cd "$mnt_repo"

    NIX_CONFIG='experimental-features = nix-command flakes' \
        nixos-generate-config --root /mnt

    success "Hardware config generated"
}

#==============================================================================
# Process configs: delete configuration.nix, move hardware-configuration.nix
#==============================================================================
process_configs() {
    section "Processing Configuration Files"
    local mnt_etc_nixos="/mnt/etc/nixos"
    local repo_name
    repo_name="$(basename "$(cd "$(dirname "$0")/.." && pwd)")"
    local mnt_repo="$mnt_etc_nixos/$repo_name"
    local hosts_dir="$mnt_repo/hosts/laptop"

    info "Checking generated files..."

    # Check configuration.nix exists
    if [[ ! -f "$mnt_etc_nixos/configuration.nix" ]]; then
        error "Expected file not found: $mnt_etc_nixos/configuration.nix"
        exit 1
    fi

    # Check hardware-configuration.nix exists
    if [[ ! -f "$mnt_etc_nixos/hardware-configuration.nix" ]]; then
        error "Expected file not found: $mnt_etc_nixos/hardware-configuration.nix"
        exit 1
    fi

    # Delete configuration.nix (we use flake-based config)
    info "Removing $mnt_etc_nixos/configuration.nix..."
    rm -f "$mnt_etc_nixos/configuration.nix"

    # Move hardware-configuration.nix to hosts/laptop/
    info "Moving hardware-configuration.nix to $hosts_dir/..."
    mv "$mnt_etc_nixos/hardware-configuration.nix" "$hosts_dir/"

    success "Configuration files processed"
}

#==============================================================================
# Show UUID placeholders and prompt to edit
#==============================================================================
edit_uuids() {
    section "UUID Configuration"
    local hosts_dir="$1"

    info "Current UUID settings in hardware-configuration.nix:"
    echo ""
    grep -n "by-uuid" "$hosts_dir/hardware-configuration.nix" || true
    echo ""

    # Show blkid output for reference
    info "Available block devices and UUIDs (from blkid):"
    echo ""
    blkid 2>/dev/null | grep -E "(UUID|PARTUUID)" || true
    echo ""

    info "If LUKS/ESP UUIDs show as <LUKS-UUID>/<ESP-UUID>, they need to be replaced"
    pause "Press Enter to edit hardware-configuration.nix, or Ctrl+C to skip... "
    ${EDITOR:-nano} "$hosts_dir/hardware-configuration.nix"
}

#==============================================================================
# Run nixos-install
#==============================================================================
do_install() {
    section "NixOS Installation"
    local mnt_etc_nixos="/mnt/etc/nixos"
    local repo_name
    repo_name="$(basename "$(cd "$(dirname "$0")/.." && pwd)")"
    local mnt_repo="$mnt_etc_nixos/$repo_name"

    cd "$mnt_repo"
    info "Working directory: $(pwd)"
    echo ""

    # Get username
    local userName
    read -p "Username for the new user [default: mccarnon]: " userName
    userName="${userName:-mccarnon}"
    echo ""

    # Get password
    local userPassword
    read -sp "Password for $userName: " userPassword
    echo ""
    echo ""

    info "Starting nixos-install..."
    echo "This may take a while. Go make some tea."
    echo ""

    # Set password for the user that will be created
    # We'll pass it via nixos-install
    export NIX_CONFIG='experimental-features = nix-command flakes'

    # Run nixos-install
    # Note: We use --no-root-password and set up the user via configuration
    nixos-install --flake .#laptop --no-root-password

    if [[ $? -eq 0 ]]; then
        success "NixOS installed successfully!"
        echo ""
        info "Next steps:"
        echo "  1. Reboot: sudo reboot"
        echo "  2. At boot, enter LUKS password when prompted"
        echo "  3. Login as $userName"
        echo "  4. Run: cd ~/Nixos-Configuration && git add -A && sudo nixos-rebuild switch --flake .#laptop"
    else
        error "Installation failed"
        exit 1
    fi
}

#==============================================================================
# Main
#==============================================================================
main() {
    echo ""
    echo "============================================"
    echo "  NixOS Installation Script"
    echo "  (disko + config generation + nixos-install)"
    echo "============================================"
    echo ""

    check_root
    setup_nix

    local script_dir
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    local repo_root="$(cd "$script_dir/.." && pwd)"
    local disko_file="$repo_root/hosts/laptop/disko-fs.nix"
    local mnt_etc_nixos="/mnt/etc/nixos"

    # Step 1: Disko
    check_disk "$disko_file"
    pause "Press Enter to start disko (or Ctrl+C to exit)... "
    run_disko "$disko_file"

    # Step 2: Copy repo
    copy_repo

    # Step 3: Generate and process config
    local hosts_dir="$mnt_etc_nixos/$(basename "$repo_root")/hosts/laptop"

    # Check if we have a pre-configured hardware-configuration.nix (no placeholders)
    if [[ -f "$hosts_dir/hardware-configuration.nix" ]] && \
       ! grep -q "<LUKS-UUID>" "$hosts_dir/hardware-configuration.nix" 2>/dev/null; then
        warn "Found pre-configured hardware-configuration.nix, skipping generation"
    else
        generate_config
        process_configs
        edit_uuids "$hosts_dir"
    fi

    # Step 4: Install
    do_install
}

main "$@"
