#!/bin/bash
################################################################################
# Ruflo - Install Script for SuperClaude Integration
################################################################################
#
# Installs Ruflo (AI orchestration platform) alongside SuperClaude Framework.
#
# One-line install:
#   curl -fsSL https://raw.githubusercontent.com/bradydefibaugh/ruflo/main/scripts/install-ruflo.sh | bash
#
# With options:
#   curl -fsSL ... | bash -s -- --full       # Include MCP server setup
#   curl -fsSL ... | bash -s -- --global     # Global npm install
#   curl -fsSL ... | bash -s -- --minimal    # Skip optional deps
#
################################################################################

set -euo pipefail

# --- Configuration ---
RUFLO_PACKAGE="ruflo"
MIN_NODE_MAJOR=20
MIN_NPM_MAJOR=9

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Options ---
INSTALL_MODE="npx"       # npx | global | minimal
SETUP_MCP=false
RUN_DOCTOR=false
VERSION=""

# --- Helpers ---
info()    { printf "${BLUE}[info]${NC}  %s\n" "$*"; }
ok()      { printf "${GREEN}[ok]${NC}    %s\n" "$*"; }
warn()    { printf "${YELLOW}[warn]${NC}  %s\n" "$*"; }
err()     { printf "${RED}[error]${NC} %s\n" "$*" >&2; }
step()    { printf "${CYAN}==> %s${NC}\n" "$*"; }

# --- Argument parsing ---
while [[ $# -gt 0 ]]; do
    case $1 in
        --global|-g)   INSTALL_MODE="global"; shift ;;
        --minimal)     INSTALL_MODE="minimal"; shift ;;
        --full|-f)     INSTALL_MODE="global"; SETUP_MCP=true; RUN_DOCTOR=true; shift ;;
        --setup-mcp)   SETUP_MCP=true; shift ;;
        --doctor)      RUN_DOCTOR=true; shift ;;
        --version=*)   VERSION="${1#*=}"; shift ;;
        --help|-h)
            cat <<'USAGE'
Ruflo Install Script

Usage:
  curl -fsSL <url> | bash
  curl -fsSL <url> | bash -s -- [OPTIONS]

Options:
  --global, -g    Install globally via npm install -g
  --minimal       Minimal install (skip optional dependencies)
  --full, -f      Full setup: global install + MCP + diagnostics
  --setup-mcp     Configure Ruflo as an MCP server for Claude Code
  --doctor        Run diagnostics after install
  --version=X.Y.Z Install a specific version
  --help, -h      Show this help message

Default (no flags):
  Verifies prerequisites and sets up Ruflo via npx (no global install).
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

check_node() {
    step "Checking Node.js"

    if ! command -v node &>/dev/null; then
        err "Node.js is not installed"
        info "Install Node.js ${MIN_NODE_MAJOR}+ from https://nodejs.org/"
        info "Or use nvm: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash"
        exit 1
    fi

    local ver
    ver=$(node --version | sed 's/^v//')
    local major
    major=$(echo "$ver" | cut -d. -f1)

    if [ "$major" -lt "$MIN_NODE_MAJOR" ]; then
        err "Node.js v$ver found, but v${MIN_NODE_MAJOR}+ is required"
        info "Upgrade Node.js: https://nodejs.org/"
        exit 1
    fi

    ok "Node.js v$ver"
}

check_npm() {
    step "Checking npm"

    if ! command -v npm &>/dev/null; then
        err "npm is not installed"
        info "npm should come with Node.js. Reinstall Node.js from https://nodejs.org/"
        exit 1
    fi

    local ver
    ver=$(npm --version)
    local major
    major=$(echo "$ver" | cut -d. -f1)

    if [ "$major" -lt "$MIN_NPM_MAJOR" ]; then
        warn "npm v$ver found; v${MIN_NPM_MAJOR}+ recommended"
        info "Upgrade: npm install -g npm@latest"
    else
        ok "npm v$ver"
    fi
}

check_claude_code() {
    step "Checking Claude Code CLI"

    if command -v claude &>/dev/null; then
        ok "Claude Code CLI found"
        return 0
    fi

    warn "Claude Code CLI not found"
    info "Install from: https://docs.anthropic.com/en/docs/claude-code"
    info "Ruflo will still install, but MCP integration requires Claude Code"
    return 1
}

# --- Installation ---

install_ruflo() {
    local pkg="$RUFLO_PACKAGE"
    if [ -n "$VERSION" ]; then
        pkg="${RUFLO_PACKAGE}@${VERSION}"
    fi

    case "$INSTALL_MODE" in
        global)
            step "Installing Ruflo globally"
            npm install -g "$pkg"
            ok "Ruflo installed globally"
            ;;
        minimal)
            step "Installing Ruflo globally (minimal)"
            npm install -g "$pkg" --omit=optional
            ok "Ruflo installed (minimal)"
            ;;
        npx)
            step "Verifying Ruflo via npx"
            if npx "$pkg" --version &>/dev/null; then
                local ver
                ver=$(npx "$pkg" --version 2>/dev/null || echo "latest")
                ok "Ruflo $ver available via npx"
            else
                warn "Could not verify Ruflo via npx; it will be fetched on first run"
                ok "Ruflo configured for npx usage"
            fi
            ;;
    esac
}

setup_mcp_server() {
    step "Configuring Ruflo as MCP server"

    if ! command -v claude &>/dev/null; then
        warn "Claude Code CLI not found, skipping MCP setup"
        info "After installing Claude Code, run: claude mcp add ruflo -- npx -y ruflo@latest mcp start"
        return
    fi

    if claude mcp add ruflo -- npx -y "${RUFLO_PACKAGE}@latest" mcp start 2>/dev/null; then
        ok "Ruflo MCP server configured"
    else
        warn "MCP server setup had issues"
        info "Manual setup: claude mcp add ruflo -- npx -y ruflo@latest mcp start"
    fi
}

run_doctor() {
    step "Running diagnostics"

    if [ "$INSTALL_MODE" = "npx" ]; then
        npx "${RUFLO_PACKAGE}@latest" doctor 2>/dev/null && ok "Diagnostics passed" || warn "Diagnostics had warnings"
    else
        ruflo doctor 2>/dev/null && ok "Diagnostics passed" || warn "Diagnostics had warnings"
    fi
}

verify() {
    step "Verifying installation"

    local ruflo_cmd
    if [ "$INSTALL_MODE" = "npx" ]; then
        ruflo_cmd="npx ${RUFLO_PACKAGE}@latest"
    else
        ruflo_cmd="ruflo"
    fi

    if command -v ruflo &>/dev/null || [ "$INSTALL_MODE" = "npx" ]; then
        ok "Ruflo ready"
    else
        warn "ruflo not found in PATH (restart your shell)"
    fi
}

# --- Main ---

main() {
    printf "\n"
    printf "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "${CYAN}  Ruflo Installer${NC}\n"
    printf "${CYAN}  AI Orchestration for SuperClaude${NC}\n"
    printf "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "\n"

    info "Mode: $INSTALL_MODE"
    if [ -n "$VERSION" ]; then
        info "Version: $VERSION"
    fi
    printf "\n"

    # Prerequisites
    check_node
    check_npm
    local has_claude=true
    check_claude_code || has_claude=false
    printf "\n"

    # Install
    install_ruflo
    printf "\n"

    # Optional: MCP setup
    if [ "$SETUP_MCP" = true ] && [ "$has_claude" = true ]; then
        setup_mcp_server
        printf "\n"
    fi

    # Optional: diagnostics
    if [ "$RUN_DOCTOR" = true ]; then
        run_doctor
        printf "\n"
    fi

    # Verify
    verify
    printf "\n"

    # Done
    printf "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "${GREEN}  Installation complete!${NC}\n"
    printf "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "\n"

    info "Quick start:"
    if [ "$INSTALL_MODE" = "npx" ]; then
        echo "  npx ruflo@latest init --wizard   # Interactive setup"
        echo "  npx ruflo@latest status           # Check system status"
    else
        echo "  ruflo init --wizard               # Interactive setup"
        echo "  ruflo status                      # Check system status"
    fi
    printf "\n"

    if [ "$has_claude" = true ] && [ "$SETUP_MCP" != true ]; then
        info "MCP integration (optional):"
        echo "  claude mcp add ruflo -- npx -y ruflo@latest mcp start"
        printf "\n"
    fi

    info "Docs: https://github.com/bradydefibaugh/ruflo"
    printf "\n"
}

main
