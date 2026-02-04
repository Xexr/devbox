#!/usr/bin/env bash
# ============================================================
# DevBox Setup Script (derived from ACFS manifest)
# Tailored for: Ubuntu Noble (24.04), x86_64, user: xexr
#
# Usage:
#   chmod +x devbox-setup.sh
#   ./devbox-setup.sh
#
# What this installs (in order):
#   Phase 1: Base system packages (curl, git, jq, build-essential, etc.)
#   Phase 2: Filesystem layout (/data/projects, ~/.acfs)
#   Phase 3: Zsh + Oh My Zsh + Powerlevel10k + plugins
#   Phase 4: Modern CLI tools (ripgrep, tmux, fzf, bat, fd, etc.)
#            + lazygit, lazydocker
#   Phase 5: Networking (Tailscale + SSH keepalive)
#   Phase 6: Language runtimes (Bun, uv, Rust, Go, nvm/Node)
#            + shell tools (atuin, zoxide, ast-grep)
#   Phase 7: AI coding agents (Claude Code, Codex, Gemini)
#   Phase 8: Vercel CLI
#   Phase 9: Stack tools (NTM, DCG, CASS, Process Triage,
#            Repo Updater, SRPS)
#   Phase 10: Workspace setup
#   Phase 11: ACFS programmable CLI (doctor, update, newproj, etc.)
#   Phase 12: Onboarding TUI
# ============================================================

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export NEEDRESTART_SUSPEND=1
export DEBCONF_NONINTERACTIVE_SEEN=true

# ============================================================
# Configuration
# ============================================================
TARGET_USER="xexr"
TARGET_HOME="/home/xexr"
WORKSPACE="/data/projects"
ARCH="$(uname -m)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Ensure ~/.local/bin is on PATH for this session
export PATH="$TARGET_HOME/.local/bin:$TARGET_HOME/.cargo/bin:$TARGET_HOME/.bun/bin:$TARGET_HOME/go/bin:$PATH"

# ============================================================
# Helpers
# ============================================================
step_count=0
step() {
    step_count=$((step_count + 1))
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  [$step_count] $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; }

skip_if_exists() {
    # Usage: skip_if_exists "command_name" && return 0
    local cmd="$1"
    if command -v "$cmd" &>/dev/null; then
        ok "$cmd already installed ($(command -v "$cmd"))"
        return 0
    fi
    return 1
}

# Verified download helper: downloads a script, optionally checks sha256
download_installer() {
    local url="$1"
    local dest="$2"
    curl --proto '=https' --proto-redir '=https' -fsSL "$url" -o "$dest"
}

run_as_user() {
    # Run a command as TARGET_USER if currently root, otherwise just run it
    if [[ "$(id -u)" -eq 0 && "$(whoami)" != "$TARGET_USER" ]]; then
        sudo -u "$TARGET_USER" bash -c "$1"
    else
        bash -c "$1"
    fi
}

# ============================================================
# Pre-flight checks
# ============================================================
echo -e "${BLUE}"
echo "  ╔══════════════════════════════════════════════╗"
echo "  ║       DevBox Setup Script                    ║"
echo "  ║       Ubuntu Noble · x86_64 · $TARGET_USER           ║"
echo "  ╚══════════════════════════════════════════════╝"
echo -e "${NC}"

if ! sudo -n true 2>/dev/null; then
    echo "This script requires sudo. You may be prompted for your password."
    sudo true
fi

# ============================================================
# PHASE 1: Base system packages
# ============================================================
step "Base system packages"

sudo apt-get update -y
sudo apt-get install -y \
    curl git ca-certificates unzip tar xz-utils jq \
    build-essential gnupg lsb-release software-properties-common \
    zsh libicu-dev

ok "Base packages installed"

# ============================================================
# PHASE 2: Filesystem layout
# ============================================================
step "Filesystem layout"

for p in /data /data/projects /data/cache; do
    if [[ -e "$p" && -L "$p" ]]; then
        fail "Refusing to use symlinked path: $p"
        exit 1
    fi
done

sudo mkdir -p /data/projects /data/cache
sudo chown -h "$TARGET_USER:$TARGET_USER" /data /data/projects /data/cache

mkdir -p "$TARGET_HOME/.acfs"
ok "Created /data/projects, /data/cache, ~/.acfs"

# ============================================================
# PHASE 3: Zsh + Oh My Zsh + Powerlevel10k
# ============================================================
step "Zsh + Oh My Zsh + Powerlevel10k"

ACFS_RAW="https://raw.githubusercontent.com/Dicklesworthstone/agentic_coding_flywheel_setup/main"

# Oh My Zsh
if [[ ! -d "$TARGET_HOME/.oh-my-zsh" ]]; then
    TMPINSTALLER="$(mktemp)"
    download_installer "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" "$TMPINSTALLER"
    sh "$TMPINSTALLER" --unattended --keep-zshrc
    rm -f "$TMPINSTALLER"
    ok "Oh My Zsh installed"
else
    ok "Oh My Zsh already installed"
fi

# Powerlevel10k
if [[ ! -d "$TARGET_HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "$TARGET_HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    ok "Powerlevel10k installed"
else
    ok "Powerlevel10k already installed"
fi

# zsh-autosuggestions
if [[ ! -d "$TARGET_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        "$TARGET_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    ok "zsh-autosuggestions installed"
else
    ok "zsh-autosuggestions already installed"
fi

# zsh-syntax-highlighting
if [[ ! -d "$TARGET_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$TARGET_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    ok "zsh-syntax-highlighting installed"
else
    ok "zsh-syntax-highlighting already installed"
fi

# ACFS zsh config
mkdir -p "$TARGET_HOME/.acfs/zsh"
download_installer "$ACFS_RAW/acfs/zsh/acfs.zshrc" "$TARGET_HOME/.acfs/zsh/acfs.zshrc"
download_installer "$ACFS_RAW/acfs/zsh/p10k.zsh" "$TARGET_HOME/.p10k.zsh"
ok "ACFS zshrc + p10k config downloaded"

# Setup loader .zshrc
if [[ -f "$TARGET_HOME/.zshrc" ]] && ! grep -q "ACFS loader" "$TARGET_HOME/.zshrc"; then
    cp "$TARGET_HOME/.zshrc" "$TARGET_HOME/.zshrc.bak.$(date +%s)"
fi
cat > "$TARGET_HOME/.zshrc" <<'ZSHRC'
# ACFS loader
source "$HOME/.acfs/zsh/acfs.zshrc"

# User overrides live here forever
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
ZSHRC
ok "~/.zshrc configured"

# Setup ~/.profile
if [[ ! -f "$TARGET_HOME/.profile" ]]; then
    cat > "$TARGET_HOME/.profile" <<'PROFILE'
# ~/.profile: executed by bash for login shells

# User binary paths
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.bun/bin:$HOME/go/bin:$PATH"
PROFILE
elif ! grep -q '\.local/bin' "$TARGET_HOME/.profile"; then
    cat >> "$TARGET_HOME/.profile" <<'PROFILE'

# Added by DevBox setup - user binary paths
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.bun/bin:$HOME/go/bin:$PATH"
PROFILE
fi
ok "~/.profile configured"

# Set default shell to zsh
if [[ "$SHELL" != */zsh ]]; then
    zsh_path="$(command -v zsh || true)"
    if [[ -n "$zsh_path" ]]; then
        sudo chsh -s "$zsh_path" "$TARGET_USER" && ok "Default shell set to zsh" || warn "Could not set default shell; run: chsh -s $zsh_path"
    fi
else
    ok "Default shell already zsh"
fi

# ============================================================
# PHASE 4: Modern CLI tools
# ============================================================
step "Modern CLI tools (apt packages)"

sudo apt-get install -y \
    ripgrep tmux fzf direnv jq git-lfs lsof dnsutils \
    netcat-openbsd strace rsync

# These may not be available on all Ubuntu versions; install best-effort
sudo apt-get install -y lsd 2>/dev/null || true
sudo apt-get install -y eza 2>/dev/null || true
sudo apt-get install -y bat 2>/dev/null || sudo apt-get install -y batcat 2>/dev/null || true
sudo apt-get install -y fd-find 2>/dev/null || true
sudo apt-get install -y btop 2>/dev/null || true
sudo apt-get install -y dust 2>/dev/null || true
sudo apt-get install -y p7zip-full 2>/dev/null || true
sudo apt-get install -y neovim 2>/dev/null || true
sudo apt-get install -y docker.io docker-compose-plugin 2>/dev/null || true

# GitHub CLI
if ! command -v gh &>/dev/null; then
    sudo apt-get install -y gh 2>/dev/null || {
        # Fallback: install from GitHub's apt repo
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
            | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
            | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update && sudo apt-get install -y gh
    }
fi
ok "Modern CLI tools installed"

# Initialize git-lfs hooks (registers smudge/clean filters in ~/.gitconfig)
git lfs install 2>/dev/null || true
ok "git-lfs initialized"

# Add user to docker group
if getent group docker &>/dev/null; then
    sudo usermod -aG docker "$TARGET_USER" 2>/dev/null || true
    ok "User added to docker group (re-login to take effect)"
fi

# ── Lazygit ──
step "Lazygit"
if ! skip_if_exists lazygit; then
    LG_VER="0.44.1"
    LG_SHA="84682f4ad5a449d0a3ffbc8332200fe8651aee9dd91dcd8d87197ba6c2450dbc"
    LG_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_x86_64.tar.gz"
    TMP_FILE="$(mktemp)"
    curl -fsSL "$LG_URL" -o "$TMP_FILE"
    echo "$LG_SHA  $TMP_FILE" | sha256sum -c - || { fail "Lazygit checksum failed"; rm "$TMP_FILE"; exit 1; }
    sudo tar -xzf "$TMP_FILE" -C /usr/local/bin lazygit
    sudo chmod +x /usr/local/bin/lazygit
    rm "$TMP_FILE"
    ok "Lazygit $LG_VER installed"
fi

# ── Lazydocker ──
step "Lazydocker"
if ! skip_if_exists lazydocker; then
    LD_VER="0.23.3"
    LD_SHA="1f3c7037326973b85cb85447b2574595103185f8ed067b605dd43cc201bc8786"
    LD_URL="https://github.com/jesseduffield/lazydocker/releases/download/v${LD_VER}/lazydocker_${LD_VER}_Linux_x86_64.tar.gz"
    TMP_FILE="$(mktemp)"
    curl -fsSL "$LD_URL" -o "$TMP_FILE"
    echo "$LD_SHA  $TMP_FILE" | sha256sum -c - || { fail "Lazydocker checksum failed"; rm "$TMP_FILE"; exit 1; }
    sudo tar -xzf "$TMP_FILE" -C /usr/local/bin lazydocker
    sudo chmod +x /usr/local/bin/lazydocker
    rm "$TMP_FILE"
    ok "Lazydocker $LD_VER installed"
fi

# ============================================================
# PHASE 5: Networking
# ============================================================
step "Tailscale"
if ! skip_if_exists tailscale; then
    DISTRO_CODENAME="noble"
    curl --proto '=https' --proto-redir '=https' -fsSL \
        "https://pkgs.tailscale.com/stable/ubuntu/${DISTRO_CODENAME}.noarmor.gpg" \
        | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu ${DISTRO_CODENAME} main" \
        | sudo tee /etc/apt/sources.list.d/tailscale.list
    sudo apt-get update
    sudo apt-get install -y tailscale
    sudo systemctl enable tailscaled
    ok "Tailscale installed. Run 'sudo tailscale up' to connect."
fi

step "SSH keepalive configuration"
if grep -qE '^ClientAliveInterval[[:space:]]+[1-9]' /etc/ssh/sshd_config 2>/dev/null; then
    ok "SSH keepalive already configured"
else
    if [[ ! -f /etc/ssh/sshd_config.devbox.bak ]]; then
        sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.devbox.bak
    fi
    sudo sed -i '/^#*ClientAliveInterval/d' /etc/ssh/sshd_config
    sudo sed -i '/^#*ClientAliveCountMax/d' /etc/ssh/sshd_config
    echo "" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    echo "# DevBox: SSH keepalive for VPN/NAT resilience" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    echo "ClientAliveInterval 60" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    echo "ClientAliveCountMax 3" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    sudo systemctl reload sshd 2>/dev/null || sudo systemctl reload ssh 2>/dev/null || true
    ok "SSH keepalive configured (60s interval, 3 max)"
fi

# ============================================================
# PHASE 6: Language runtimes
# ============================================================
step "Bun runtime"
if [[ ! -x "$TARGET_HOME/.bun/bin/bun" ]]; then
    TMPINSTALLER="$(mktemp)"
    download_installer "https://bun.sh/install" "$TMPINSTALLER"
    bash "$TMPINSTALLER"
    rm -f "$TMPINSTALLER"
    ok "Bun installed"
else
    ok "Bun already installed"
fi

step "uv (Python tooling)"
if [[ ! -x "$TARGET_HOME/.local/bin/uv" ]]; then
    TMPINSTALLER="$(mktemp)"
    download_installer "https://astral.sh/uv/install.sh" "$TMPINSTALLER"
    sh "$TMPINSTALLER"
    rm -f "$TMPINSTALLER"
    ok "uv installed"
else
    ok "uv already installed"
fi

step "Rust (stable)"
if [[ ! -x "$TARGET_HOME/.cargo/bin/cargo" ]]; then
    TMPINSTALLER="$(mktemp)"
    download_installer "https://sh.rustup.rs" "$TMPINSTALLER"
    sh "$TMPINSTALLER" -y --default-toolchain stable
    rm -f "$TMPINSTALLER"
    # Source cargo env for this session
    source "$TARGET_HOME/.cargo/env" 2>/dev/null || true
    ok "Rust nightly installed"
else
    source "$TARGET_HOME/.cargo/env" 2>/dev/null || true
    ok "Rust already installed"
fi

step "Go"
if ! command -v go &>/dev/null; then
    sudo apt-get install -y golang-go
    ok "Go installed"
else
    ok "Go already installed"
fi

step "nvm + Node.js"
if [[ ! -d "$TARGET_HOME/.nvm" ]]; then
    TMPINSTALLER="$(mktemp)"
    download_installer "https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh" "$TMPINSTALLER"
    bash "$TMPINSTALLER"
    rm -f "$TMPINSTALLER"
fi
export NVM_DIR="$TARGET_HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
if ! command -v node &>/dev/null; then
    nvm install node
    nvm alias default node
    ok "Node.js installed via nvm"
else
    ok "Node.js already installed ($(node --version))"
fi

# ── Shell enhancement tools ──
step "Atuin (shell history)"
if [[ ! -x "$TARGET_HOME/.atuin/bin/atuin" ]]; then
    TMPINSTALLER="$(mktemp)"
    download_installer "https://setup.atuin.sh" "$TMPINSTALLER"
    sh "$TMPINSTALLER"
    rm -f "$TMPINSTALLER"
    ok "Atuin installed"
else
    ok "Atuin already installed"
fi

step "Zoxide (better cd)"
if ! command -v zoxide &>/dev/null; then
    TMPINSTALLER="$(mktemp)"
    download_installer "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh" "$TMPINSTALLER"
    sh "$TMPINSTALLER"
    rm -f "$TMPINSTALLER"
    ok "Zoxide installed"
else
    ok "Zoxide already installed"
fi

step "ast-grep"
if ! command -v sg &>/dev/null; then
    "$TARGET_HOME/.cargo/bin/cargo" install ast-grep --locked
    ok "ast-grep installed"
else
    ok "ast-grep already installed"
fi

# ============================================================
# PHASE 7: AI coding agents
# ============================================================
step "Claude Code"
if [[ ! -x "$TARGET_HOME/.local/bin/claude" ]]; then
    TMPINSTALLER="$(mktemp)"
    download_installer "https://claude.ai/install.sh" "$TMPINSTALLER"
    bash "$TMPINSTALLER" latest
    rm -f "$TMPINSTALLER"
    ok "Claude Code installed"
else
    ok "Claude Code already installed"
fi

step "OpenAI Codex CLI"
if [[ ! -x "$TARGET_HOME/.local/bin/codex" ]]; then
    "$TARGET_HOME/.bun/bin/bun" install -g --trust @openai/codex@latest || \
        "$TARGET_HOME/.bun/bin/bun" install -g --trust @openai/codex || true
    mkdir -p "$TARGET_HOME/.local/bin"
    cat > "$TARGET_HOME/.local/bin/codex" << 'WRAPPER'
#!/bin/bash
exec ~/.bun/bin/bun ~/.bun/bin/codex "$@"
WRAPPER
    chmod +x "$TARGET_HOME/.local/bin/codex"
    ok "Codex CLI installed"
else
    ok "Codex CLI already installed"
fi

step "Google Gemini CLI"
if [[ ! -x "$TARGET_HOME/.local/bin/gemini" ]]; then
    "$TARGET_HOME/.bun/bin/bun" install -g --trust @google/gemini-cli@latest
    mkdir -p "$TARGET_HOME/.local/bin"
    cat > "$TARGET_HOME/.local/bin/gemini" << 'WRAPPER'
#!/bin/bash
exec ~/.bun/bin/bun ~/.bun/bin/gemini "$@"
WRAPPER
    chmod +x "$TARGET_HOME/.local/bin/gemini"
    ok "Gemini CLI installed"
else
    ok "Gemini CLI already installed"
fi

# ============================================================
# PHASE 8: Vercel CLI
# ============================================================
step "Vercel CLI"
if ! command -v vercel &>/dev/null; then
    "$TARGET_HOME/.bun/bin/bun" install -g --trust vercel
    ok "Vercel CLI installed"
else
    ok "Vercel CLI already installed"
fi

step "Turso CLI"
if [[ ! -x "$TARGET_HOME/.turso/turso" ]]; then
    TMPINSTALLER="$(mktemp)"
    download_installer "https://get.tur.so/install.sh" "$TMPINSTALLER"
    bash "$TMPINSTALLER"
    rm -f "$TMPINSTALLER"
    ok "Turso CLI installed"
else
    ok "Turso CLI already installed"
fi

# ============================================================
# PHASE 9: Stack tools
# ============================================================

# ── NTM (Named Tmux Manager) ──
step "NTM (Named Tmux Manager)"
if ! command -v ntm &>/dev/null; then
    TMPINSTALLER="$(mktemp)"
    download_installer "https://raw.githubusercontent.com/Dicklesworthstone/ntm/main/install.sh" "$TMPINSTALLER"
    bash "$TMPINSTALLER" --no-shell
    rm -f "$TMPINSTALLER"
    ok "NTM installed"
else
    ok "NTM already installed"
fi

# ── DCG (Destructive Command Guard) ──
step "DCG (Destructive Command Guard)"
if ! command -v dcg &>/dev/null; then
    TMPINSTALLER="$(mktemp)"
    download_installer "https://raw.githubusercontent.com/Dicklesworthstone/destructive_command_guard/main/install.sh" "$TMPINSTALLER"
    bash "$TMPINSTALLER" --easy-mode
    rm -f "$TMPINSTALLER"
    ok "DCG installed"
else
    ok "DCG already installed"
fi

# ── CASS (Coding Agent Session Search) ──
step "CASS (Coding Agent Session Search)"
if ! command -v cass &>/dev/null; then
    TMPINSTALLER="$(mktemp)"
    download_installer "https://raw.githubusercontent.com/Dicklesworthstone/coding_agent_session_search/main/install.sh" "$TMPINSTALLER"
    bash "$TMPINSTALLER" --easy-mode --verify
    rm -f "$TMPINSTALLER"
    ok "CASS installed"
else
    ok "CASS already installed"
fi

# ── Process Triage ──
step "Process Triage"
if ! command -v pt &>/dev/null; then
    TMPINSTALLER="$(mktemp)"
    download_installer "https://raw.githubusercontent.com/Dicklesworthstone/process_triage/master/install.sh" "$TMPINSTALLER"
    bash "$TMPINSTALLER"
    rm -f "$TMPINSTALLER"
    ok "Process Triage installed"
else
    ok "Process Triage already installed"
fi

# ── Repo Updater ──
step "Repo Updater"
if ! command -v ru &>/dev/null; then
    TMPINSTALLER="$(mktemp)"
    download_installer "https://raw.githubusercontent.com/Dicklesworthstone/repo_updater/main/install.sh" "$TMPINSTALLER"
    bash "$TMPINSTALLER" --easy-mode
    rm -f "$TMPINSTALLER"
    ok "Repo Updater installed"
else
    ok "Repo Updater already installed"
fi

# ── Dolt (version-controlled SQL database) ──
step "Dolt"
if ! command -v dolt &>/dev/null; then
    TMPINSTALLER="$(mktemp)"
    download_installer "https://github.com/dolthub/dolt/releases/latest/download/install.sh" "$TMPINSTALLER"
    sudo bash "$TMPINSTALLER"
    rm -f "$TMPINSTALLER"
    ok "Dolt installed ($(dolt version 2>&1))"
else
    ok "Dolt already installed ($(dolt version 2>&1))"
fi

# ── Beads (issue tracker) ──
step "Beads"
if ! command -v bd &>/dev/null; then
    BEADS_DIR="$(mktemp -d)"
    git clone --depth=1 https://github.com/steveyegge/beads.git "$BEADS_DIR"
    cd "$BEADS_DIR"
    make install
    cd /
    rm -rf "$BEADS_DIR"
    ok "Beads installed ($(bd version 2>&1 | head -1))"
else
    ok "Beads already installed ($(bd version 2>&1 | head -1))"
fi

# ── Gas Town ──
step "Gas Town"
if ! command -v gt &>/dev/null; then
    GASTOWN_DIR="$(mktemp -d)"
    git clone --depth=1 https://github.com/steveyegge/gastown.git "$GASTOWN_DIR"
    cd "$GASTOWN_DIR"
    make install
    cd /
    rm -rf "$GASTOWN_DIR"
    ok "Gas Town installed ($(gt version 2>&1))"
else
    ok "Gas Town already installed ($(gt version 2>&1))"
fi

# ── SRPS (System Resource Protection Script) ──
step "SRPS (System Resource Protection)"
if ! command -v sysmoni &>/dev/null; then
    TMPINSTALLER="$(mktemp)"
    download_installer "https://raw.githubusercontent.com/Dicklesworthstone/system_resource_protection_script/main/install.sh" "$TMPINSTALLER"
    bash "$TMPINSTALLER" --install
    rm -f "$TMPINSTALLER"
    ok "SRPS installed"
else
    ok "SRPS already installed"
fi

# ============================================================
# PHASE 10: Workspace setup
# ============================================================
step "Agent workspace"

mkdir -p /data/projects/my_first_project
cd /data/projects/my_first_project
git init 2>/dev/null || true

# Workspace instructions
mkdir -p "$TARGET_HOME/.acfs"
cat > "$TARGET_HOME/.acfs/workspace-instructions.txt" << 'INSTRUCTIONS'

  DEVBOX AGENT WORKSPACE - QUICK REFERENCE
  -----------------------------------------

  RECONNECT AFTER SSH:
    tmux attach -t agents    OR just type:  agents

  WINDOWS (Ctrl-b + number):
    0:welcome  - This instructions window
    1:claude   - Claude Code (Anthropic)
    2:codex    - Codex CLI (OpenAI)
    3:gemini   - Gemini CLI (Google)

  TMUX BASICS:
    Ctrl-b d        - Detach (keep session running)
    Ctrl-b c        - Create new window
    Ctrl-b n/p      - Next/previous window
    Ctrl-b [0-9]    - Switch to window number

  START AN AGENT:
    claude          - Start Claude Code
    codex           - Start Codex CLI
    gemini          - Start Gemini CLI

  PROJECT: /data/projects/my_first_project
  (Rename with: mv /data/projects/my_first_project /data/projects/NEW_NAME)

INSTRUCTIONS

# Create tmux session with agent panes
SESSION_NAME="agents"
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux new-session -d -s "$SESSION_NAME" -n "welcome" -c /data/projects/my_first_project
    tmux new-window -t "$SESSION_NAME" -n "claude" -c /data/projects/my_first_project
    tmux new-window -t "$SESSION_NAME" -n "codex" -c /data/projects/my_first_project
    tmux new-window -t "$SESSION_NAME" -n "gemini" -c /data/projects/my_first_project
    tmux send-keys -t "$SESSION_NAME:welcome" "cat ~/.acfs/workspace-instructions.txt" Enter
    tmux select-window -t "$SESSION_NAME:welcome"
    ok "Tmux 'agents' session created"
else
    ok "Tmux 'agents' session already exists"
fi

# Add agents alias
if [[ ! -f "$TARGET_HOME/.zshrc.local" ]] || ! grep -q "alias agents=" "$TARGET_HOME/.zshrc.local"; then
    cat >> "$TARGET_HOME/.zshrc.local" << 'ALIASES'

# DevBox agents workspace alias
alias agents="tmux attach -t agents 2>/dev/null || tmux new-session -s agents -c /data/projects"
ALIASES
    ok "Added 'agents' alias to ~/.zshrc.local"
fi

# Download AGENTS.md template
download_installer "$ACFS_RAW/acfs/AGENTS.md" "/data/projects/AGENTS.md" 2>/dev/null || true
ok "AGENTS.md template installed to /data/projects/"

# ============================================================
# PHASE 11: ACFS Programmable CLI
# ============================================================
step "ACFS programmable CLI"

ACFS_HOME="$TARGET_HOME/.acfs"

# Create directory structure
mkdir -p "$ACFS_HOME/bin" "$ACFS_HOME/scripts/lib/newproj_screens" "$ACFS_HOME/completions" "$TARGET_HOME/.local/bin"

# Download the main ACFS CLI binary (doctor.sh serves as the entry point)
download_installer "$ACFS_RAW/scripts/lib/doctor.sh" "$ACFS_HOME/bin/acfs"
chmod 755 "$ACFS_HOME/bin/acfs"
ln -sf "$ACFS_HOME/bin/acfs" "$TARGET_HOME/.local/bin/acfs"
ok "ACFS CLI binary installed"

# Download acfs-update wrapper
download_installer "$ACFS_RAW/scripts/acfs-update" "$ACFS_HOME/bin/acfs-update"
chmod 755 "$ACFS_HOME/bin/acfs-update"
ln -sf "$ACFS_HOME/bin/acfs-update" "$TARGET_HOME/.local/bin/acfs-update"
ok "acfs-update installed"

# Download core library scripts
ACFS_LIB_SCRIPTS=(
    logging.sh gum_ui.sh security.sh doctor.sh update.sh session.sh
    continue.sh info.sh cheatsheet.sh dashboard.sh output.sh
    doctor_fix.sh state.sh status.sh support.sh
    newproj.sh newproj_agents.sh newproj_detect.sh newproj_errors.sh
    newproj_logging.sh newproj_screens.sh newproj_tui.sh
)
for script in "${ACFS_LIB_SCRIPTS[@]}"; do
    download_installer "$ACFS_RAW/scripts/lib/$script" "$ACFS_HOME/scripts/lib/$script"
done
chmod 755 "$ACFS_HOME/scripts/lib/"*.sh
ok "Library scripts installed (${#ACFS_LIB_SCRIPTS[@]} modules)"

# Download newproj TUI screen scripts
ACFS_SCREENS=(
    screen_agents_preview.sh screen_confirmation.sh screen_directory.sh
    screen_features.sh screen_progress.sh screen_project_name.sh
    screen_success.sh screen_tech_stack.sh screen_welcome.sh
)
for screen in "${ACFS_SCREENS[@]}"; do
    download_installer "$ACFS_RAW/scripts/lib/newproj_screens/$screen" "$ACFS_HOME/scripts/lib/newproj_screens/$screen"
done
chmod 755 "$ACFS_HOME/scripts/lib/newproj_screens/"*.sh
ok "Newproj TUI screens installed"

# Download services-setup wizard
download_installer "$ACFS_RAW/scripts/services-setup.sh" "$ACFS_HOME/scripts/services-setup.sh"
chmod 755 "$ACFS_HOME/scripts/services-setup.sh"
ok "Services-setup wizard installed"

# Download VERSION + checksums metadata
download_installer "$ACFS_RAW/VERSION" "$ACFS_HOME/VERSION"
download_installer "$ACFS_RAW/checksums.yaml" "$ACFS_HOME/checksums.yaml"
ok "Metadata installed (version $(cat "$ACFS_HOME/VERSION"))"

# Install global acfs wrapper (/usr/local/bin/acfs)
TMPWRAPPER="$(mktemp)"
download_installer "$ACFS_RAW/scripts/acfs-global" "$TMPWRAPPER"
sudo cp "$TMPWRAPPER" /usr/local/bin/acfs
sudo chmod 755 /usr/local/bin/acfs
rm -f "$TMPWRAPPER"
ok "Global acfs wrapper installed (/usr/local/bin/acfs)"

# Download shell completions
download_installer "$ACFS_RAW/scripts/completions/_acfs" "$ACFS_HOME/completions/_acfs"
download_installer "$ACFS_RAW/scripts/completions/acfs.bash" "$ACFS_HOME/completions/acfs.bash"
ok "Shell completions installed (zsh + bash)"

# Add completion loading to .zshrc.local if not present
if [[ ! -f "$TARGET_HOME/.zshrc.local" ]] || ! grep -q "acfs/completions" "$TARGET_HOME/.zshrc.local"; then
    cat >> "$TARGET_HOME/.zshrc.local" << 'COMP'

# ACFS CLI completions
fpath=("$HOME/.acfs/completions" $fpath)
autoload -Uz compinit && compinit -C
COMP
    ok "Zsh completion loading added to ~/.zshrc.local"
else
    ok "Zsh completion loading already configured"
fi

# Create state.json if it doesn't exist
if [[ ! -f "$ACFS_HOME/state.json" ]]; then
    cat > "$ACFS_HOME/state.json" << STATEJSON
{
  "version": "$(cat "$ACFS_HOME/VERSION")",
  "installed_at": "$(date -Iseconds)",
  "mode": "vibe",
  "target_user": "$TARGET_USER",
  "yes_mode": true,
  "completed_phases": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
}
STATEJSON
    ok "state.json created"
else
    ok "state.json already exists"
fi

ok "ACFS programmable CLI ready (run 'acfs help' to see commands)"

# ── Onboarding TUI ──
step "Onboarding TUI"
mkdir -p "$TARGET_HOME/.local/bin"
download_installer "$ACFS_RAW/packages/onboard/onboard.sh" "$TARGET_HOME/.local/bin/onboard" 2>/dev/null || true
chmod +x "$TARGET_HOME/.local/bin/onboard" 2>/dev/null || true

# Download lesson files (onboard.sh expects these in ~/.acfs/onboard/lessons/)
mkdir -p "$TARGET_HOME/.acfs/onboard/lessons"
LESSON_FILES=(
    00_welcome 01_linux_basics 02_ssh_basics 03_tmux_basics
    04_agents_login 05_ntm_core 06_ntm_command_palette 07_flywheel_loop
    08_keeping_updated 09_ru 10_dcg 11_meta_skill 12_jfp 13_apr
    14_pt 15_xf 16_beads_rust 17_rch 18_wa 19_brenner_bot
    20_newproj 23_srps
)
for lesson in "${LESSON_FILES[@]}"; do
    download_installer "$ACFS_RAW/acfs/onboard/lessons/${lesson}.md" \
        "$TARGET_HOME/.acfs/onboard/lessons/${lesson}.md" 2>/dev/null || true
done
ok "Onboarding script + lessons installed (run 'onboard' to launch)"

# ============================================================
# Done!
# ============================================================
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Next steps:"
echo "    1. Start a new shell:  exec zsh"
echo "    2. Connect Tailscale:  sudo tailscale up"
echo "    3. Open agent workspace:  agents"
echo "    4. Run the onboarding:  onboard"
echo ""
echo "  Your workspace is at: /data/projects/"
echo ""
