#!/usr/bin/env bash
# claude-project-status: Bash integration
# Sources the core detection library and hooks into PROMPT_COMMAND.
#
# Usage: Add to ~/.bashrc:
#   source /path/to/claude_project_status/integrations/bash.bash
#
# Works with static PS1 and dynamic themes (Oh My Bash, etc.) that rebuild
# PS1 on every prompt. Our hook runs AFTER the theme's PROMPT_COMMAND so
# the patch is always applied to the freshly-built PS1.

# Guard against double-sourcing
if [[ "$(type -t _claude_project_prompt_command)" == "function" ]]; then
    return 0
fi

# Resolve the real directory of this script
_cps_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source core libraries
source "${_cps_dir}/lib/format.sh"
source "${_cps_dir}/lib/detect.sh"

# Patch PS1 to include the claude segment if not already present
_claude_bash_patch_ps1() {
    if [[ "$PS1" == *'$_CLAUDE_PS_CACHED_OUTPUT'* ]]; then
        return 0  # Already patched
    fi

    if [[ "$PS1" == *'\$ '* ]]; then
        PS1="${PS1/\\$ /\$_CLAUDE_PS_CACHED_OUTPUT\\$ }"
    elif [[ "$PS1" == *'$ '* ]]; then
        PS1="${PS1/\$ /\$_CLAUDE_PS_CACHED_OUTPUT\$ }"
    else
        PS1="${PS1}"'$_CLAUDE_PS_CACHED_OUTPUT'
    fi
}

# Detect Warp terminal with its own prompt rendering
_CLAUDE_PS_USE_RPROMPT=0
if [[ "$TERM_PROGRAM" == "WarpTerminal" && "${WARP_HONOR_PS1:-0}" == "0" ]]; then
    _CLAUDE_PS_USE_RPROMPT=1
fi

# Run detection AND re-patch PS1 on every prompt render.
# Re-patching is needed because dynamic themes (Oh My Bash, etc.)
# rebuild PS1 from scratch in their own PROMPT_COMMAND.
# In Warp (WARP_HONOR_PS1=0), use PS0/title escape as a visible indicator
# since Warp doesn't support bash RPROMPT natively.
_claude_project_prompt_command() {
    _claude_detect_project
    if [[ "$_CLAUDE_PS_USE_RPROMPT" == "1" ]]; then
        # Warp mode: set terminal title to include project info
        if [[ -n "$_CLAUDE_PS_NAME" ]]; then
            printf '\e]0;%s [claude:%s]\a' "${PWD##*/}" "$_CLAUDE_PS_NAME"
        fi
    else
        _claude_bash_patch_ps1
    fi
}

# APPEND to PROMPT_COMMAND (run AFTER theme's command, so we patch the fresh PS1)
if [[ -z "${PROMPT_COMMAND:-}" ]]; then
    PROMPT_COMMAND="_claude_project_prompt_command"
else
    PROMPT_COMMAND="${PROMPT_COMMAND};_claude_project_prompt_command"
fi
