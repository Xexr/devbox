# DevBox Setup

Personal development environment setup script, based on the [Agentic Coding Flywheel Setup (ACFS)](https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup).

Bootstraps an Ubuntu 24.04 (Noble) devbox with a complete AI-assisted coding environment in a single run.

## What it installs

- **Shell**: Zsh, Oh My Zsh, Powerlevel10k, Atuin, Zoxide
- **CLI tools**: ripgrep, fd, bat, fzf, lsd/eza, btop, dust, lazygit, lazydocker, 7z
- **Language runtimes**: Rust (nightly), Go, Node.js (nvm), Bun, Python (uv)
- **AI coding agents**: Claude Code, OpenAI Codex, Google Gemini
- **Databases**: Dolt, Turso CLI
- **Infrastructure**: Docker, Tailscale, Vercel CLI
- **ACFS stack tools**: NTM, DCG, CASS, Process Triage, Repo Updater, SRPS, Beads
- **ACFS programmable CLI**: `acfs doctor`, `acfs update`, `acfs newproj`, etc.

## Usage

```bash
chmod +x devbox-setup.sh
./devbox-setup.sh
```

## Based on

[ACFS](https://github.com/Dicklesworthstone/agentic_coding_flywheel_setup) by Jeff Dicklesworth — adapted for personal use with a tailored tool selection and install flow.
