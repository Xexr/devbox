# DevBox Setup

Personal development environment setup script, based on the [Agentic Coding Flywheel Setup (ACFS)](https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup).

Bootstraps an Ubuntu 24.04 (Noble) devbox with a complete AI-assisted coding environment in a single run. The goal is to go from a bare VPS to a productive, agent-driven development workflow with one script.

## Usage

```bash
chmod +x devbox-setup.sh
./devbox-setup.sh
```

## What it installs

### Shell environment

The shell is where you live. This setup makes it fast, informative, and pleasant.

| Tool | What it does |
|------|-------------|
| **Zsh** | Modern shell with better scripting, globbing, and plugin support than bash |
| **Oh My Zsh** | Plugin framework for Zsh — adds git status, auto-completion, syntax highlighting |
| **Powerlevel10k** | Fast, informative prompt that shows git branch, runtime versions, and command duration at a glance |
| **zsh-autosuggestions** | Ghost-text suggestions from your history as you type — accept with right arrow |
| **zsh-syntax-highlighting** | Colors your commands as you type — red means invalid, green means valid |
| **Atuin** | Replaces Ctrl+R with a searchable, synced shell history across sessions and machines |
| **Zoxide** | Smarter `cd` — learns your most-used directories so `z proj` jumps to `/data/projects` |
| **direnv** | Automatically loads/unloads environment variables when you enter/leave a project directory |

### Modern CLI tools

Replacements for standard Unix tools that are faster, more readable, and more useful.

| Tool | Replaces | Why it's better |
|------|----------|----------------|
| **ripgrep (rg)** | grep | 10-100x faster, respects `.gitignore`, better regex |
| **fd** | find | Simpler syntax, faster, ignores hidden/gitignored files by default |
| **bat** | cat | Syntax highlighting, line numbers, git integration |
| **fzf** | — | Fuzzy finder for files, history, branches — pipes into anything |
| **lsd / eza** | ls | Icons, colors, tree view, git status per file |
| **btop** | top/htop | Beautiful system monitor with CPU, memory, disk, and network graphs |
| **dust** | du | Visual disk usage breakdown — instantly see what's eating space |
| **lazygit** | git CLI | Full TUI for git — stage, commit, rebase, resolve conflicts interactively |
| **lazydocker** | docker CLI | TUI for Docker — view containers, logs, stats without memorizing flags |
| **neovim** | vim | Modern vim with better defaults, async plugins, and LSP support |
| **GitHub CLI (gh)** | browser | Create PRs, review issues, trigger workflows from the terminal |
| **ast-grep (sg)** | grep (for code) | Structural code search using AST patterns — finds code by meaning, not text |
| **7z (p7zip)** | — | Universal archive handling — used by the `extract` shell function |

### Language runtimes

Everything you need to build in the most common languages, with modern tooling.

| Tool | What it does |
|------|-------------|
| **Rust** (via rustup) | Systems language — installed via rustup so you can switch toolchains easily |
| **Go** | Compiled language with excellent concurrency — used by many CLI tools and infrastructure projects |
| **Node.js** (via nvm) | JavaScript runtime — nvm lets you switch between Node versions per project |
| **Bun** | Fast JavaScript runtime and package manager — used to install global JS-based CLI tools |
| **Python** (via uv) | uv is a fast Python package manager and virtualenv tool — replaces pip, venv, and pyenv in one |

### AI coding agents

Three AI agents, each with different strengths. Run them side-by-side in dedicated tmux windows.

| Agent | Provider | What it does |
|-------|----------|-------------|
| **Claude Code** | Anthropic | Agentic coding assistant — reads your codebase, makes edits, runs commands |
| **Codex CLI** | OpenAI | OpenAI's coding agent — similar workflow, different model strengths |
| **Gemini CLI** | Google | Google's coding agent — large context window, good for exploration |

The install creates a tmux session called `agents` with dedicated windows for each. Type `agents` to attach.

### Infrastructure and cloud

| Tool | What it does |
|------|-------------|
| **Docker** | Container runtime — run databases, services, and builds in isolation |
| **Tailscale** | Mesh VPN — secure access to your devbox from anywhere without port forwarding |
| **Vercel CLI** | Deploy frontend apps directly from the terminal |
| **Turso CLI** | Manage Turso/libSQL cloud databases — SQLite at the edge |

### Dev tools

| Tool | What it does |
|------|-------------|
| **Beads** (bd) | Git-native issue tracker — issues live in your repo, not a separate service. Supports AI agent workflows |
| **Dolt** | Version-controlled SQL database — branch, merge, diff, and clone databases like git repos |

### ACFS stack tools

Purpose-built tools for the agentic coding workflow.

| Tool | What it does |
|------|-------------|
| **NTM** | Named Tmux Manager — launch and manage tmux sessions with predefined layouts |
| **DCG** | Destructive Command Guard — intercepts dangerous commands (rm -rf, drop table) before they execute |
| **CASS** | Coding Agent Session Search — archive and search through past AI agent conversations |
| **Process Triage** (pt) | Identify and manage runaway processes — useful when agents spawn builds that hang |
| **Repo Updater** (ru) | Batch-update multiple git repos — pull, rebase, or run commands across all your projects |
| **SRPS** | System Resource Protection — monitors CPU, memory, and disk to prevent agents from exhausting resources |

### ACFS programmable CLI

The `acfs` command provides a unified interface for managing your environment.

| Command | What it does |
|---------|-------------|
| `acfs doctor` | Health check — verifies all tools are installed and working |
| `acfs update` | Update all ACFS tools and agents to latest versions |
| `acfs newproj` | Scaffold a new project with git, config, and agent instructions |
| `acfs services-setup` | Configure API keys and authentication for all services |
| `acfs info` | Quick system overview — hostname, IP, uptime, versions |
| `acfs cheatsheet` | Command reference for all aliases and shortcuts |
| `acfs session` | Export, import, and search agent session histories |

## Based on

[ACFS](https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup) by Jeff Dicklesworth — adapted for personal use with a tailored tool selection and install flow.
