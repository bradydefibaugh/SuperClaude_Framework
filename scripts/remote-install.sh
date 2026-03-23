#!/bin/bash
################################################################################
# SuperClaude Framework - Remote Installer
################################################################################
#
# One-line installation:
#   curl -fsSL https://raw.githubusercontent.com/SuperClaude-Org/SuperClaude_Framework/master/scripts/remote-install.sh | bash
#
# Or with options:
#   curl -fsSL https://raw.githubusercontent.com/SuperClaude-Org/SuperClaude_Framework/master/scripts/remote-install.sh | bash -s -- --yes
#   curl -fsSL https://raw.githubusercontent.com/SuperClaude-Org/SuperClaude_Framework/master/scripts/remote-install.sh | bash -s -- --dev
#
# This script:
#   1. Checks prerequisites (Python 3.10+, git)
#   2. Installs UV package manager if missing
#   3. Installs SuperClaude via pipx (default) or in dev mode (--dev)
#   4. Runs `superclaude install` to set up slash commands
#   5. Verifies the installation
#
################################################################################

set -euo pipefail

# --- Configuration ---
REPO_URL="https://github.com/SuperClaude-Org/SuperClaude_Framework.git"
PACKAGE_NAME="superclaude"
MIN_PYTHON_MAJOR=3
MIN_PYTHON_MINOR=10

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Options ---
AUTO_YES=false
DEV_MODE=false
INSTALL_DIR=""

# --- Helpers ---
info()    { printf "${BLUE}[info]${NC}  %s\n" "$*"; }
ok()      { printf "${GREEN}[ok]${NC}    %s\n" "$*"; }
warn()    { printf "${YELLOW}[warn]${NC}  %s\n" "$*"; }
err()     { printf "${RED}[error]${NC} %s\n" "$*" >&2; }
step()    { printf "${CYAN}==> %s${NC}\n" "$*"; }

confirm() {
    if [ "$AUTO_YES" = true ]; then return 0; fi
    printf "%s [Y/n] " "$1"
    read -r response
    case "${response:-y}" in
        [Yy]*) return 0 ;;
        *) return 1 ;;
    esac
}

cleanup() {
    if [ -n "$INSTALL_DIR" ] && [ -d "$INSTALL_DIR" ] && [ "$DEV_MODE" = false ]; then
        rm -rf "$INSTALL_DIR"
    fi
}
trap cleanup EXIT

# --- Argument parsing ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --yes|-y)   AUTO_YES=true; shift ;;
        --dev|-d)   DEV_MODE=true; shift ;;
        --help|-h)
            cat <<'USAGE'
SuperClaude Framework - Remote Installer

Usage:
  curl -fsSL <url> | bash
  curl -fsSL <url> | bash -s -- [OPTIONS]

Options:
  --yes, -y     Non-interactive mode (auto-accept prompts)
  --dev, -d     Clone repo and install in editable/development mode
  --help, -h    Show this help message

Default (no flags):
  Installs via pipx for an isolated, user-level installation.

Development mode (--dev):
  Clones the repository to ~/SuperClaude_Framework and installs
  in editable mode with dev dependencies using UV.
USAGE
            exit 0
            ;;
        *)
            err "Unknown option: $1"
            err "Run with --help for usage information"
            exit 1
            ;;
    esac
done

# --- Prerequisite checks ---

check_python() {
    step "Checking Python"

    if ! command -v python3 &>/dev/null; then
        err "Python 3 is not installed"
        info "Install Python 3.10+ from https://www.python.org/ or via your package manager"
        exit 1
    fi

    local ver
    ver=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    local major minor
    major=$(echo "$ver" | cut -d. -f1)
    minor=$(echo "$ver" | cut -d. -f2)

    if [ "$major" -lt "$MIN_PYTHON_MAJOR" ] || { [ "$major" -eq "$MIN_PYTHON_MAJOR" ] && [ "$minor" -lt "$MIN_PYTHON_MINOR" ]; }; then
        err "Python $ver found, but $MIN_PYTHON_MAJOR.$MIN_PYTHON_MINOR+ is required"
        exit 1
    fi

    ok "Python $ver"
}

check_git() {
    step "Checking Git"

    if ! command -v git &>/dev/null; then
        err "Git is required but not installed"
        info "Install from https://git-scm.com/ or via your package manager"
        exit 1
    fi

    ok "Git $(git --version | awk '{print $3}')"
}

ensure_uv() {
    if command -v uv &>/dev/null; then
        ok "UV $(uv --version 2>&1 | awk '{print $2}')"
        return
    fi

    step "Installing UV package manager"
    if ! confirm "UV is required for development mode. Install now?"; then
        err "UV is required. Install manually: curl -LsSf https://astral.sh/uv/install.sh | sh"
        exit 1
    fi

    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

    if ! command -v uv &>/dev/null; then
        err "UV installed but not found in PATH. Restart your shell and try again."
        exit 1
    fi

    ok "UV installed"
}

ensure_pipx() {
    if command -v pipx &>/dev/null; then
        ok "pipx $(pipx --version 2>&1)"
        return
    fi

    step "Installing pipx"
    if ! confirm "pipx is recommended for installation. Install now?"; then
        err "pipx is required for standard install. Use --dev for development mode instead."
        exit 1
    fi

    python3 -m pip install --user pipx 2>/dev/null || pip install --user pipx
    python3 -m pipx ensurepath 2>/dev/null || true
    export PATH="$HOME/.local/bin:$PATH"

    if ! command -v pipx &>/dev/null; then
        err "pipx installed but not found in PATH. Restart your shell and try again."
        exit 1
    fi

    ok "pipx installed"
}

# --- Installation ---

install_via_pipx() {
    step "Installing SuperClaude via pipx"

    if pipx install "$PACKAGE_NAME" 2>/dev/null; then
        ok "SuperClaude package installed"
    else
        warn "pipx install failed, trying from git..."
        pipx install "git+${REPO_URL}"
        ok "SuperClaude package installed from git"
    fi
}

install_dev_mode() {
    INSTALL_DIR="$HOME/SuperClaude_Framework"

    if [ -d "$INSTALL_DIR" ]; then
        info "Directory $INSTALL_DIR already exists"
        if confirm "Pull latest changes?"; then
            git -C "$INSTALL_DIR" pull origin master
        fi
    else
        step "Cloning repository"
        git clone "$REPO_URL" "$INSTALL_DIR"
        ok "Repository cloned to $INSTALL_DIR"
    fi

    step "Installing in development mode"
    cd "$INSTALL_DIR"
    uv pip install -e ".[dev]"
    ok "SuperClaude installed in editable mode"
}

install_slash_commands() {
    step "Installing slash commands"

    if ! command -v superclaude &>/dev/null; then
        export PATH="$HOME/.local/bin:$PATH"
    fi

    if command -v superclaude &>/dev/null; then
        superclaude install && ok "Slash commands installed" || warn "Slash command install had warnings"
    else
        warn "superclaude CLI not found in PATH - skipping slash command install"
        info "After restarting your shell, run: superclaude install"
    fi
}

verify() {
    step "Verifying installation"

    if command -v superclaude &>/dev/null; then
        local ver
        ver=$(superclaude --version 2>&1 || echo "unknown")
        ok "SuperClaude $ver"
    else
        warn "superclaude not in PATH yet (restart your shell)"
    fi
}

# --- Main ---

main() {
    printf "\n"
    printf "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "${CYAN}  SuperClaude Framework Installer${NC}\n"
    printf "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "\n"

    if [ "$DEV_MODE" = true ]; then
        info "Mode: Development (editable install)"
    else
        info "Mode: Standard (pipx)"
    fi
    printf "\n"

    # Prerequisites
    check_python
    check_git

    if [ "$DEV_MODE" = true ]; then
        ensure_uv
        install_dev_mode
    else
        ensure_pipx
        install_via_pipx
    fi

    install_slash_commands
    verify

    # Done
    printf "\n"
    printf "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "${GREEN}  Installation complete!${NC}\n"
    printf "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "\n"
    info "Next steps:"
    echo "  superclaude doctor          # Run health check"
    echo "  superclaude install --list  # View installed commands"
    echo "  superclaude mcp             # Install MCP servers (optional)"
    printf "\n"

    if [ "$DEV_MODE" = true ]; then
        info "Dev repo: $INSTALL_DIR"
        echo "  cd $INSTALL_DIR"
        echo "  uv run pytest              # Run tests"
        echo "  make test                  # Or use make"
        printf "\n"
    fi

    info "Docs: https://github.com/SuperClaude-Org/SuperClaude_Framework"
    printf "\n"
}

main
