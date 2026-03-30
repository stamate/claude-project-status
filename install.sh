#!/bin/sh
# claude-project-status: Installer
# Adds source lines to shell config files and optionally symlinks the CLI tool.
# Idempotent — safe to run multiple times.
#
# Usage: ./install.sh [--zsh] [--bash] [--both] [--link] [--uninstall]

set -e

CPS_ROOT="$(cd "$(dirname "$0")" && pwd)"

# Defaults
INSTALL_ZSH=0
INSTALL_BASH=0
INSTALL_LINK=0
UNINSTALL=0

# Parse args
if [ $# -eq 0 ]; then
    # Auto-detect current shell
    case "${SHELL:-}" in
        */zsh)  INSTALL_ZSH=1 ;;
        */bash) INSTALL_BASH=1 ;;
        *)      INSTALL_ZSH=1 ;;  # default to zsh on macOS
    esac
fi

while [ $# -gt 0 ]; do
    case "$1" in
        --zsh)       INSTALL_ZSH=1; shift ;;
        --bash)      INSTALL_BASH=1; shift ;;
        --both)      INSTALL_ZSH=1; INSTALL_BASH=1; shift ;;
        --link)      INSTALL_LINK=1; shift ;;
        --uninstall) UNINSTALL=1; shift ;;
        -h|--help)
            cat << 'EOF'
claude-project-status installer

Usage: ./install.sh [OPTIONS]

Options:
  --zsh        Install for Zsh (~/.zshrc)
  --bash       Install for Bash (~/.bashrc)
  --both       Install for both shells
  --link       Symlink claude-project-info to ~/.local/bin/
  --uninstall  Remove all installed lines and symlinks
  -h, --help   Show this help

With no options, auto-detects your current shell.
EOF
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            exit 2
            ;;
    esac
done

ZSH_SOURCE_LINE="source \"${CPS_ROOT}/integrations/zsh.zsh\""
BASH_SOURCE_LINE="source \"${CPS_ROOT}/integrations/bash.bash\""
MARKER="# claude-project-status"

# --- Uninstall ---
if [ "$UNINSTALL" = "1" ]; then
    printf 'Uninstalling claude-project-status...\n'

    for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
        if [ -f "$rc" ] && grep -q "$MARKER" "$rc"; then
            # Remove lines containing the marker
            tmp=$(mktemp)
            grep -v "$MARKER" "$rc" > "$tmp"
            mv "$tmp" "$rc"
            printf '  Removed from %s\n' "$rc"
        fi
    done

    if [ -L "$HOME/.local/bin/claude-project-info" ]; then
        rm "$HOME/.local/bin/claude-project-info"
        printf '  Removed symlink ~/.local/bin/claude-project-info\n'
    fi

    printf 'Done. Restart your shell or run: exec $SHELL\n'
    exit 0
fi

# --- Install ---
printf 'Installing claude-project-status...\n'

if [ "$INSTALL_ZSH" = "1" ]; then
    ZSHRC="$HOME/.zshrc"
    if [ ! -f "$ZSHRC" ]; then
        touch "$ZSHRC"
    fi

    if grep -q "claude_project_status" "$ZSHRC" 2>/dev/null; then
        printf '  Zsh: Already installed in %s\n' "$ZSHRC"
    else
        printf '\n%s %s\n' "$ZSH_SOURCE_LINE" "$MARKER" >> "$ZSHRC"
        printf '  Zsh: Added to %s\n' "$ZSHRC"
    fi
fi

if [ "$INSTALL_BASH" = "1" ]; then
    BASHRC="$HOME/.bashrc"
    if [ ! -f "$BASHRC" ]; then
        touch "$BASHRC"
    fi

    if grep -q "claude_project_status" "$BASHRC" 2>/dev/null; then
        printf '  Bash: Already installed in %s\n' "$BASHRC"
    else
        printf '\n%s %s\n' "$BASH_SOURCE_LINE" "$MARKER" >> "$BASHRC"
        printf '  Bash: Added to %s\n' "$BASHRC"
    fi
fi

if [ "$INSTALL_LINK" = "1" ]; then
    LINK_DIR="$HOME/.local/bin"
    mkdir -p "$LINK_DIR"
    LINK_PATH="$LINK_DIR/claude-project-info"
    if [ -L "$LINK_PATH" ] || [ -f "$LINK_PATH" ]; then
        printf '  CLI: %s already exists\n' "$LINK_PATH"
    else
        ln -s "$CPS_ROOT/bin/claude-project-info" "$LINK_PATH"
        printf '  CLI: Symlinked to %s\n' "$LINK_PATH"
    fi
fi

printf '\nDone! Restart your shell or run: exec $SHELL\n'
printf '\nVerify with:\n'
printf '  cd /some/claude/project && claude-project-info\n'
